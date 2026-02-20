local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()
config:set_strict_mode(true)

-- General

-- config.font = wezterm.font 'CaskaydiaCove Nerd Font'
config.font = wezterm.font 'SauceCodePro Nerd Font'
config.font_size = 15
-- config.color_scheme = 'Catppuccin Mocha (Gogh)'
config.color_scheme = 'Earthsong (Gogh)'
config.colors = {
  split = wezterm.color.get_builtin_schemes()[config.color_scheme].ansi[2],
}
config.window_close_confirmation = 'NeverPrompt' -- For quitting WezTerm

-- Performance Hack
config.max_fps = 120
config.animation_fps = 120


local TITLEBAR_COLOR = '#333333'
config.native_macos_fullscreen_mode = true
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_frame = {
  -- font = wezterm.font { family = 'CaskaydiaCove Nerd Font', weight = 'Bold' },
  font = wezterm.font { family = 'SauceCodePro Nerd Font', weight = 'Bold' },
  font_size = 14.0,
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
