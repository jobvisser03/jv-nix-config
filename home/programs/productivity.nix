{
  pkgs,
  ...
}: {
  programs = {
    oh-my-posh = {
      enable = true;
      settings = {
        final_space = true;
        shell_integration = true;
        enable_cursor_positioning = true;
        iterm_features = [
          "remote_host"
          "current_dir"
        ];
        blocks = [
          {
            alignment = "left";
            segments = [
              {
                background = "#d3d7cf";
                foreground = "#000000";
                style = "diamond";
                template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
                type = "os";
              }
              {
                background = "#3465a4";
                foreground = "#e4e4e4";
                powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
                properties = {
                  home_icon = "~";
                  style = "full";
                };
                style = "powerline";
                template = builtins.fromJSON ''" \uf07c {{ .Path }} "'';
                type = "path";
              }
              {
                background = "#4e9a06";
                background_templates = [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}#c4a000{{ end }}"
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#f26d50{{ end }}"
                  "{{ if gt .Ahead 0 }}#89d1dc{{ end }}"
                  "{{ if gt .Behind 0 }}#4e9a06{{ end }}"
                ];
                foreground = "#000000";
                powerline_symbol = builtins.fromJSON ''"\ue0b0"'';
                properties = {
                  branch_icon = builtins.fromJSON ''"\uf126 "'';
                  fetch_stash_count = true;
                  fetch_status = true;
                  fetch_upstream_icon = true;
                };
                style = "powerline";
                template = builtins.fromJSON ''" {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} "'';
                type = "git";
              }
            ];
            type = "prompt";
          }
          {
            alignment = "left";
            newline = true;
            segments = [
              {
                foreground = "#81ff91";
                foreground_templates = ["{{if gt .Code 0}}#ff3030{{end}}"];
                style = "diamond";
                template = builtins.fromJSON ''"\u276f"'';
                properties.always_enabled = true;
                type = "text";
              }
            ];
            type = "prompt";
          }
        ];
        console_title_template = "{{ .Shell }} in {{ .Folder }}";
        version = 3;
      };
    };

    pandoc.enable = true;

    kitty.enable = true;

    wezterm = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      extraConfig = builtins.readFile ../../non-nix-configs/wezterm.lua;
    };
  };
}
