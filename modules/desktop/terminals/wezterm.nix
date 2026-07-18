# Wezterm terminal configuration
# Home-manager only module
{...}: {
  flake.modules.homeManager.wezterm = {
    pkgs,
    lib,
    config,
    ...
  }: let
    # Use stylix monospace font if available, otherwise fall back to a default
    fontName =
      if config ? stylix && config.stylix ? fonts
      then config.stylix.fonts.monospace.name
      else "SauceCodePro Nerd Font";
    fontSize =
      if config ? stylix && config.stylix ? fonts
      then config.stylix.fonts.sizes.terminal
      else 16;
  in {
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      extraConfig = ''
        local wezterm = require 'wezterm'
        local act = wezterm.action

        local config = wezterm.config_builder()
        config:set_strict_mode(true)

        -- General (using stylix fonts)
        config.font = wezterm.font '${fontName}'
        config.font_size = ${toString fontSize}
        config.window_close_confirmation = 'NeverPrompt'

        -- Colors (match previous working theme)
        --config.color_scheme = 'Catppuccin Mocha (Gogh)'
        -- config.color_scheme = 'Chalkboard'
        -- config.color_scheme = 'Earthsong (Gogh)'
        -- config.color_scheme = 'Cobalt 2 (Gogh)' -- white cursor
        -- config.color_scheme = 'Chameleon (Gogh)' -- brown, too dark
        --config.color_scheme = 'Ciapre' -- brown
        -- config.color_scheme = 'Cobalt 2 (Gogh)'
        -- config.color_scheme = 'Cobalt Neon (Gogh)'
        config.color_scheme = 'Cobalt2'
        -- config.color_scheme = 'Tomorrow (dark) (terminal.sexy)'
        config.colors = {
          split = wezterm.color.get_builtin_schemes()[config.color_scheme].ansi[2],
        }

        -- Performance
        config.max_fps = 120
        config.animation_fps = 120

        config.native_macos_fullscreen_mode = false
        config.window_decorations = 'RESIZE'
        config.use_fancy_tab_bar = false

        config.window_background_opacity = 0.96

        wezterm.on('window-resized', function(window, pane)
          local overrides = window:get_config_overrides() or {}
          local is_fullscreen = window:get_dimensions().is_full_screen
          window:set_config_overrides(overrides)
        end)

        -- Tab bar configuration
        local known_shells = {
          bash = true, zsh = true, sh = true
        }

        local function basename(path)
          return path:gsub('(.*[/\\])(.*)', '%2'):gsub('[%.][eE][xX][eE]$', ''')
        end

        local function ternary(a, b)
          if a and a ~= ''' then
            return a
          end
          return b
        end

        local function get_title(tab, foreground)
          -- Figure out what title to show
          local pane = tab.active_pane
          local raw_title = tab.tab_title
          local ran_cmd = pane.user_vars.WEZTERM_CMD or '''
          local pane_title = pane.title
          local base_pane_title = basename(pane_title)
          local is_shell = base_pane_title ~= ''' and known_shells[base_pane_title]
          local proc_name = basename(pane.foreground_process_name)
          if raw_title == ''' then
            if pane_title == ''' then
              raw_title = ternary(ran_cmd, proc_name)
            elseif ran_cmd == ''' then
              if is_shell then
                raw_title = ternary(proc_name, base_pane_title)
              else
                raw_title = ternary(pane_title, proc_name)
              end
            else
              if is_shell then
                raw_title = ternary(ran_cmd, base_pane_title)
              else
                raw_title = ternary(pane_title, ran_cmd)
              end
            end
          end
          if raw_title == ''' then
            raw_title = ternary(proc_name, basename(os.getenv('WEZTERM_EXECUTABLE')))
          else
            raw_title = raw_title:gsub('[%.][eE][xX][eE]$', ''')
          end

        end

        config.keys = {
          { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen, },
          { key = 'q', mods = 'ALT', action = act.QuitApplication, },

          { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left', },
          { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right', },
          { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down', },
          { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up', },

          { key = 'h', mods = 'SHIFT|ALT', action = act.AdjustPaneSize {'Left', 4}, },
          { key = 'l', mods = 'SHIFT|ALT', action = act.AdjustPaneSize {'Right', 4}, },
          { key = 'j', mods = 'SHIFT|ALT', action = act.AdjustPaneSize {'Down', 4}, },
          { key = 'k', mods = 'SHIFT|ALT', action = act.AdjustPaneSize {'Up', 4}, },

          { key = '-', mods = 'ALT', action = act.SplitVertical, },
          { key = 'v', mods = 'ALT', action = act.SplitHorizontal, },

          { key = '[', mods = 'ALT', action = act.ActivateTabRelative(-1), },
          { key = ']', mods = 'ALT', action = act.ActivateTabRelative(1), },

          -- Rebind OPT-Left, OPT-Right as ALT-b, ALT-f respectively to match Terminal.app behavior
          {
            key = 'LeftArrow',
            mods = 'OPT',
            action = act.SendKey {
              key = 'b',
              mods = 'ALT',
            },
          },
          {
            key = 'RightArrow',
            mods = 'OPT',
            action = act.SendKey { key = 'f', mods = 'ALT' },
          }
        }

        table.insert(config.keys, {
          key = '4', mods = 'ALT|CTRL',
          action = wezterm.action.SpawnCommandInNewTab {
            cwd = os.getenv('HOME') .. '/repos/jv-nix-config',
            args = {'/bin/zsh', '-lc', 'code .'},
          },
        })

        return config
      '';
    };
  };
}
