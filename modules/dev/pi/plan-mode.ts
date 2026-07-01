/**
 * Plan mode extension for pi coding agent.
 *
 * Adds a /plan command that toggles a planning-first mode: when active, the
 * agent is instructed to outline its approach before making any changes.
 *
 * Usage:
 *   /plan       — toggle plan mode on/off
 *   /plan on    — enable
 *   /plan off   — disable
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

let planModeActive = false;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("plan", {
    description: "Toggle plan mode — agent plans before acting",
    handler: async (args, ctx) => {
      const arg = (args ?? "").trim().toLowerCase();
      if (arg === "on") {
        planModeActive = true;
      } else if (arg === "off") {
        planModeActive = false;
      } else {
        planModeActive = !planModeActive;
      }
      ctx.ui.notify(
        planModeActive
          ? "Plan mode ON — agent will outline a plan before acting"
          : "Plan mode OFF",
        "info",
      );
    },
  });

  pi.on("before_agent_start", async (event, _ctx) => {
    if (!planModeActive) return;
    return {
      systemPrompt:
        event.systemPrompt +
        `

## Plan Mode Active
Before making any file edits or running commands, you MUST:
1. Restate the task in your own words
2. List the steps you plan to take
3. Note any risks or assumptions

Only proceed with implementation after the plan is laid out.`,
    };
  });

  pi.on("session_start", async (_event, ctx) => {
    if (planModeActive) {
      ctx.ui.setStatus("plan-mode", "plan mode");
    }
  });
}
