return {
  {
    key = 'd',
    spec = {
      workspace = 'name:discord',
      on_created_empty = 'vesktop --ozone-platform-hint=auto'
    }
  },
  {
    key = 'g',
    spec = {
      workspace = 'name:games',
      default = false,
      on_created_empty =
      'steam --enable-features=UseOzonePlatform --ozone-platform=wayland'
    }
  },
  {
    key = 'w',
    spec = {
      workspace = 'name:whatsapp',
      default = false,
      on_created_empty =
      'chromium --app-id=hnpfjngllnobngcgfapefoaidbinmjnm'
    }
  },
  {
    key =
    'o',
    spec = {
      workspace = 'name:obs',
      default = false,
      on_created_empty =
      'obs --enable-features=UseOzonePlatform --ozone-platform=wayland'
    }
  },

  {
    key =
    'k',
    spec = {
      workspace = 'name:kovaaks',
      default = false,
      on_created_empty = 'steam -applaunch 824270 --enable-features=UseOzonePlatform --ozone-platform=wayland '
    }
  },

  {
    key = 'g',
    spec = {
      workspace = 'name:github',
      default = false,
      on_created_empty =
      'chromium --app=https://github.com/ --profile-directory="Profile 1"'
    }
  },

  {
    key = 'q',
    spec = {
      workspace        = 'name:quran',
      default          = false,
      on_created_empty = 'chromium --app=https://bayyinahtv.com/ --profile-directory="Profile 1"',
    }
  },

  {
    key = 'm',
    spec = {
      workspace = 'name:gmail',
      default = false,
      on_created_empty =
      'chromium --app=https://gmail.com --profile-directory="Profile 1"'
    }
  },
  {
    key = 'c',
    spec = {

      workspace        = 'name:calendar',
      default          = false,
      on_created_empty =
      'chromium --app=https://calendar.google.com --profile-directory="Profile 1"'
    }
  },
  {
    key = 'v',
    spec = {
      workspace = 'name:meet',
      default = false,
      on_created_empty =
      'chromium --app=https://meet.google.com --profile-directory="Profile 1"'
    }
  },

  {
    key = 'a',
    spec = {
      workspace = 'name:ai',
      on_created_empty = 'chromium --app=https://chat.deepseek.com --profile-directory="Your Chromium"',
    },
    description = 'Deepseek',
  },

  {
    key = 'y',
    spec = {
      workspace = 'name:youtube',
      on_created_empty = 'chromium --app=https://youtube.com --profile-directory="Your Chromium"',
    },
    description = 'Deepseek',
  },

  {
    key = 'i',
    spec = {
      workspace = 'name:twitch.tv',
      on_created_empty = 'chromium --app=https://twitch.com --profile-directory="Your Chromium"',
    },
    description = 'Deepseek',
  },

}
