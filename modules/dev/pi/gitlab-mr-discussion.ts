/**
 * pi-gitlab-mr-discussion — Extension for GitLab MR discussion workflows.
 *
 * Adds dedicated tools for listing, replying to, and resolving MR discussions.
 * Designed to complement @gaodes/pi-gitlab by filling the discussion UX gap.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function glab(args: string[], cwd?: string): Promise<unknown> {
  const { stdout, stderr } = await execFileAsync("glab", args, {
    cwd,
    encoding: "utf-8",
    maxBuffer: 10 * 1024 * 1024,
    env: process.env,
  });
  if (stderr?.trim() && !stdout.trim()) throw new Error(stderr.trim());
  const text = stdout.trim();
  if (!text) return {};
  try { return JSON.parse(text); } catch { return text; }
}

async function getGitRemoteProject(cwd?: string): Promise<string | null> {
  try {
    const { stdout } = await execFileAsync("git", ["remote", "get-url", "origin"], {
      cwd,
      encoding: "utf-8",
    });
    // ssh://git@host:port/group/subgroup/project.git → group/subgroup/project
    // git@host:group/project.git → group/project
    const url = stdout.trim();
    const sshMatch = url.match(/(?:ssh:\/\/[^/]+\/|git@[^:]+:)(.+?)(?:\.git)?$/);
    if (sshMatch) return sshMatch[1].replace(/^\//, "");
    const httpsMatch = url.match(/https?:\/\/[^/]+\/(.+?)(?:\.git)?$/);
    if (httpsMatch) return httpsMatch[1];
    return null;
  } catch { return null; }
}

async function resolveProject(project: string | undefined, cwd?: string): Promise<string> {
  if (project) return project;
  const gitPath = await getGitRemoteProject(cwd);
  if (gitPath) return gitPath;
  throw new Error("No project specified and could not determine from git remote.");
}

// Simple project ID cache
const projectIdCache = new Map<string, number>();

async function resolveProjectId(project: string): Promise<number> {
  const numeric = Number(project);
  if (!Number.isNaN(numeric) && numeric > 0) return numeric;
  const cached = projectIdCache.get(project);
  if (cached) return cached;

  const lastSegment = project.split("/").pop() ?? project;
  const results = await glab([
    "api", "--paginate",
    `projects?search=${encodeURIComponent(lastSegment)}&per_page=100`,
  ]) as Array<{ id: number; path_with_namespace: string }>;

  const match = results.find((r) => r.path_with_namespace === project);
  if (!match) throw new Error(`Project '${project}' not found.`);
  projectIdCache.set(project, match.id);
  return match.id;
}

// ─── Types ───────────────────────────────────────────────────────────────────

interface Note {
  id: number;
  body: string;
  author: { name: string; username: string };
  created_at: string;
  system: boolean;
  resolvable: boolean;
  resolved: boolean;
  position?: {
    old_path?: string;
    new_path?: string;
    new_line?: number;
    old_line?: number;
    position_type?: string;
  };
}

interface Discussion {
  id: string;
  individual_note: boolean;
  notes: Note[];
}

// ─── Schema helpers ──────────────────────────────────────────────────────────

const OptionalProject = Type.Optional(
  Type.String({ description: "Project path (e.g. 'group/project') or numeric ID. Falls back to git remote." })
);

// ─── Extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {

  // ═══ Tool: gitlab_mr_discussions ═══════════════════════════════════════════
  pi.registerTool({
    name: "gitlab_mr_discussions",
    label: "List MR Discussions",
    description:
      "List all discussion threads on a merge request with full context: file path, line number, body, author, resolved status. Filters out system notes by default.",
    parameters: Type.Object({
      project: OptionalProject,
      mrId: Type.Number({ description: "MR IID (project-relative number)." }),
      includeResolved: Type.Optional(Type.Boolean({ default: false, description: "Include already-resolved threads." })),
      includeSystem: Type.Optional(Type.Boolean({ default: false, description: "Include system-generated notes." })),
    }, { additionalProperties: false }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
      const projectPath = await resolveProject(params.project, ctx.cwd);
      const projectId = await resolveProjectId(projectPath);

      const discussions = await glab([
        "api", "--paginate",
        `projects/${projectId}/merge_requests/${params.mrId}/discussions`,
      ]) as Discussion[];

      const threads: string[] = [];
      let threadNum = 0;

      for (const disc of discussions) {
        if (disc.individual_note && disc.notes[0]?.system && !params.includeSystem) continue;

        const firstNote = disc.notes[0];
        if (!firstNote) continue;
        if (firstNote.system && !params.includeSystem) continue;

        const isResolved = disc.notes.some(n => n.resolved);
        if (isResolved && !params.includeResolved) continue;

        threadNum++;
        const pos = firstNote.position;
        const location = pos?.new_path
          ? `${pos.new_path}${pos.new_line ? `:${pos.new_line}` : ""}`
          : "(general)";

        const status = isResolved ? "✅ resolved" : "⏳ open";

        const lines: string[] = [];
        lines.push(`### Thread ${threadNum} — ${status}`);
        lines.push(`Discussion ID: \`${disc.id}\``);
        lines.push(`Location: \`${location}\``);
        lines.push("");

        for (const note of disc.notes) {
          if (note.system && !params.includeSystem) continue;
          lines.push(`**${note.author.name}** (@${note.author.username}) — ${note.created_at.slice(0, 10)}:`);
          lines.push(note.body);
          lines.push("");
        }

        threads.push(lines.join("\n"));
      }

      const summary = threads.length > 0
        ? `Found ${threads.length} discussion thread(s) on MR !${params.mrId}:\n\n${threads.join("\n---\n\n")}`
        : `No open discussion threads on MR !${params.mrId}.`;

      return {
        content: [{ type: "text", text: summary }],
        details: { success: true, threadCount: threads.length },
      };
    },
  });

  // ═══ Tool: gitlab_mr_discussion_reply ══════════════════════════════════════
  pi.registerTool({
    name: "gitlab_mr_discussion_reply",
    label: "Reply to MR Discussion",
    description:
      "Reply to a specific discussion thread on a merge request. Requires confirmation.",
    parameters: Type.Object({
      project: OptionalProject,
      mrId: Type.Number({ description: "MR IID." }),
      discussionId: Type.String({ description: "Discussion ID (from gitlab_mr_discussions)." }),
      body: Type.String({ description: "Reply body (markdown supported)." }),
      confirm: Type.Optional(Type.Boolean({ default: false, description: "Must be true to execute." })),
    }, { additionalProperties: false }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
      if (!params.confirm) {
        return {
          content: [{ type: "text", text: `⚠️ Reply to discussion \`${params.discussionId}\` on MR !${params.mrId}:\n\n> ${params.body}\n\nSet confirm: true to send.` }],
          details: { success: false, reason: "confirmation_required" },
        };
      }

      const projectPath = await resolveProject(params.project, ctx.cwd);
      const projectId = await resolveProjectId(projectPath);

      const result = await glab([
        "api", "--method", "POST",
        `projects/${projectId}/merge_requests/${params.mrId}/discussions/${params.discussionId}/notes`,
        "-f", `body=${params.body}`,
      ]) as { id?: number };

      return {
        content: [{ type: "text", text: `✅ Reply posted to discussion \`${params.discussionId}\` on MR !${params.mrId} (note ID: ${result.id}).` }],
        details: { success: true, noteId: result.id },
      };
    },
  });

  // ═══ Tool: gitlab_mr_discussion_resolve ════════════════════════════════════
  pi.registerTool({
    name: "gitlab_mr_discussion_resolve",
    label: "Resolve/Unresolve MR Discussion",
    description:
      "Resolve or unresolve a discussion thread on a merge request. Requires confirmation.",
    parameters: Type.Object({
      project: OptionalProject,
      mrId: Type.Number({ description: "MR IID." }),
      discussionId: Type.String({ description: "Discussion ID." }),
      resolved: Type.Boolean({ description: "true to resolve, false to unresolve." }),
      confirm: Type.Optional(Type.Boolean({ default: false, description: "Must be true to execute." })),
    }, { additionalProperties: false }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
      const action = params.resolved ? "resolve" : "unresolve";
      if (!params.confirm) {
        return {
          content: [{ type: "text", text: `⚠️ Will ${action} discussion \`${params.discussionId}\` on MR !${params.mrId}. Set confirm: true to proceed.` }],
          details: { success: false, reason: "confirmation_required" },
        };
      }

      const projectPath = await resolveProject(params.project, ctx.cwd);
      const projectId = await resolveProjectId(projectPath);

      await glab([
        "api", "--method", "PUT",
        `projects/${projectId}/merge_requests/${params.mrId}/discussions/${params.discussionId}`,
        "-f", `resolved=${params.resolved}`,
      ]);

      return {
        content: [{ type: "text", text: `✅ Discussion \`${params.discussionId}\` on MR !${params.mrId} ${action}d.` }],
        details: { success: true, action },
      };
    },
  });

  // ═══ Tool: gitlab_mr_discussion_batch_reply ════════════════════════════════
  pi.registerTool({
    name: "gitlab_mr_discussion_batch_reply",
    label: "Batch Reply to MR Discussions",
    description:
      "Reply to multiple discussion threads at once. Each reply is a {discussionId, body} pair. Requires confirmation.",
    parameters: Type.Object({
      project: OptionalProject,
      mrId: Type.Number({ description: "MR IID." }),
      replies: Type.Array(
        Type.Object({
          discussionId: Type.String({ description: "Discussion ID." }),
          body: Type.String({ description: "Reply body." }),
        }),
        { description: "List of replies to post.", minItems: 1 }
      ),
      confirm: Type.Optional(Type.Boolean({ default: false, description: "Must be true to execute." })),
    }, { additionalProperties: false }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
      if (!params.confirm) {
        const preview = params.replies.map((r, i) =>
          `${i + 1}. \`${r.discussionId}\`: ${r.body.slice(0, 60)}${r.body.length > 60 ? "…" : ""}`
        ).join("\n");
        return {
          content: [{ type: "text", text: `⚠️ Will post ${params.replies.length} replies on MR !${params.mrId}:\n\n${preview}\n\nSet confirm: true to send all.` }],
          details: { success: false, reason: "confirmation_required" },
        };
      }

      const projectPath = await resolveProject(params.project, ctx.cwd);
      const projectId = await resolveProjectId(projectPath);

      const results: Array<{ discussionId: string; noteId?: number; error?: string }> = [];

      for (const reply of params.replies) {
        try {
          const result = await glab([
            "api", "--method", "POST",
            `projects/${projectId}/merge_requests/${params.mrId}/discussions/${reply.discussionId}/notes`,
            "-f", `body=${reply.body}`,
          ]) as { id?: number };
          results.push({ discussionId: reply.discussionId, noteId: result.id });
        } catch (err) {
          results.push({ discussionId: reply.discussionId, error: String(err) });
        }
      }

      const succeeded = results.filter(r => !r.error).length;
      const failed = results.filter(r => r.error).length;
      const summary = results.map(r =>
        r.error
          ? `❌ \`${r.discussionId}\`: ${r.error}`
          : `✅ \`${r.discussionId}\` → note ${r.noteId}`
      ).join("\n");

      return {
        content: [{ type: "text", text: `Batch reply results (${succeeded} ok, ${failed} failed):\n\n${summary}` }],
        details: { success: failed === 0, results },
      };
    },
  });
}
