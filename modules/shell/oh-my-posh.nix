# Oh-My-Posh prompt configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.oh-my-posh = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
        version = 2;
        console_title_template = "{{.Folder}}{{if .Root}}::root{{end}}::{{.Shell}}";
        blocks = [
          {
            type = "prompt";
            newline = true;
            alignment = "left";
            segments = [
              {
                type = "path";
                properties = {
                  style = "powerlevel";
                  max_width = 50;
                };
                template = "{{- .Path -}}";
              }
              {
                type = "git";
                style = "plain";
              }
              {
                type = "root";
                style = "plain";
                foreground = "red";
                template = "❄️";
              }
            ];
          }
          {
            type = "prompt";
            newline = true;
            alignment = "left";
            segments = [
              {
                type = "text";
                style = "plain";
                foreground_templates = [
                  "{{if gt .Code 0}}red{{end}}"
                  "{{if eq .Code 0}}blue{{end}}"
                ];
                template = " ";
              }
            ];
          }
          {
            type = "rprompt";
            segments = [
              {
                type = "nix-shell";
                template = "{{ if .Env.name }} {{ if eq .Type \"pure\" }} {{ end }}{{ .Env.name }}{{ end }}";
              }
              {
                type = "session";
                style = "plain";
                template = "{{ if .SSHSession }}  {{ end }}   {{ .HostName }}";
              }
              {
                type = "python";
                style = "plain";
                template = builtins.concatStringsSep "" [
                  "  {{ .Full }}"
                  "{{ if .Venv }} ({{ .Venv }}){{ end }}"
                ];
              }
              {
                type = "executiontime";
                style = "plain";
                foreground = "yellow";
                properties = {
                  threshold = 5000;
                  style = "round";
                };
                template = "  {{ .FormattedMs }}";
              }
            ];
          }
        ];
        secondary_prompt = {
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}blue{{end}}"
          ];
          template = " ";
        };
        transient_prompt = {
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}blue{{end}}"
          ];
          template = " ";
        };
      };
    };
  };
}
