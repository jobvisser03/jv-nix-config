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
      else "monospace";
    fontSize =
      if config ? stylix && config.stylix ? fonts
      then config.stylix.fonts.sizes.terminal
      else 14;
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
        config.color_scheme = 'Cobalt Neon (Gogh)'
        config.colors = {
          split = wezterm.color.get_builtin_schemes()[config.color_scheme].ansi[2],
        }

        -- Performance
        config.max_fps = 120
        config.animation_fps = 120

        local TITLEBAR_COLOR = '#333333'
        config.native_macos_fullscreen_mode = true
        config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
        config.window_frame = {
          font = wezterm.font { family = '${fontName}', weight = 'Bold' },
          font_size = ${toString (fontSize - 1)},
          active_titlebar_bg = TITLEBAR_COLOR,
          inactive_titlebar_bg = TITLEBAR_COLOR,
        }

        config.window_background_opacity = 0.9

        wezterm.on('window-resized', function(window, pane)
          local overrides = window:get_config_overrides() or {}
          local is_fullscreen = window:get_dimensions().is_full_screen
          window:set_config_overrides(overrides)
        end)

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

          { key = 'd', mods = 'ALT', action = act.SplitVertical, },
          { key = 'r', mods = 'ALT', action = act.SplitHorizontal, },

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

        return config
      '';
    };
  };
}
