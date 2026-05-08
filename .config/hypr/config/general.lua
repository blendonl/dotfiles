hl.dsp.global('input');
hl.config({

  input = {
    kb_layout = 'us',
    numlock_by_default = true,
    repeat_delay = 250,
    repeat_rate = 35,
    sensitivity = 1.0,
    accel_profile = 'flat',
    force_no_accel = 1,

    left_handed = true,

    touchpad = {
      natural_scroll = false,
      disable_while_typing = true,
      clickfinger_behavior = true,
      scroll_factor = 0.5,
    },
    special_fallthrough = true,
    follow_mouse = 1,
  },


  binds = {
    scroll_event_delay = 0
  },

  general = {
    gaps_in = 0,
    gaps_out = 0,
    gaps_workspaces = 0,
    border_size = 0,
    resize_on_border = false,
    no_focus_fallback = true,
    layout = 'dwindle',
    allow_tearing = false,
  },

  decoration = {
    rounding = 0,


    dim_inactive = true,
    dim_strength = 0.5,
    dim_special = 0,
  },

  animations = {
    enabled = false,
  },

  misc = {
    vrr = 1,
    animate_manual_resizes = false,
    animate_mouse_windowdragging = false,
    enable_swallow = false,
    swallow_regex = '(foot|kitty|allacritty|Alacritty)',
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    background_color = 'rgb(000000)',
  },


  cursor = {
    no_hardware_cursors = true
  },


  xwayland = {
    force_zero_scaling = true
  },



  dwindle = {
    force_split                  = 0,
    preserve_split               = false,
    smart_split                  = false,
    smart_resizing               = true,
    permanent_direction_override = false,
    special_scale_factor         = 1,
    split_width_multiplier       = 1.0,
    use_active_for_splits        = true,
    default_split_ratio          = 1.0,
    split_bias                   = 0,
    precise_mouse_move           = false,
  }

})
