# Nix/Home Manager flake configuration

├── modules/
│   ├── default.nix          # Main modules index
│   ├── system/              # System-level modules
│   │   ├── default.nix      # System modules index
│   │   ├── nix.nix          # Nix configuration (shared substituters, etc.)
│   │   └── users.nix        # User configuration
│   └── wm/                  # Window manager modules
│       ├── default.nix      # WM modules index
│       ├── hyprland.nix
│       ├── hyprlock.nix
│       ├── hypridle.nix
│       └── waybar.nix
├── profiles/
│   ├── default.nix          # Profiles index
│   ├── desktop.nix          # Desktop environment profile
│   └── stylix.nix           # Styling profile
├── hosts/
│   ├── linux-larkbox-host/
│   │   ├── configuration.nix     # Host-specific config
│   │   └── hardware-configuration.nix
│   └── [other hosts...]
└── home/
    ├── shared-home.nix      # Shared home-manager config
    ├── home-linux.nix       # Linux-specific home config
    ├── home-nixos.nix       # NixOS-specific home config
    └── home-mac.nix         # macOS-specific home config

## Commands

Delete old generations from boot loader: `sudo nix-collect-garbage --delete-older-than 14d`

## Description

This repository contains my personal Nix/Home Manager configuration. I currently use Nix mainly in Home Manager and am very happy with it.

Main features:

- Each machine has the same command line tools with the same configuration (zsh, starship, git, ...)
- Shared command history between multiple machines thanks to atuin

I tried using nix-darwin and NixOS, but at the moment they don't bring much value to me. I work with Python a lot, in various team structures, and for now I want to keep using regular virtual environments for my Python projects, which seems like a hassle in NixOS. Thanks to nix-darwin I can now do sudo using Touch ID on my Macbook, but I don't use it for much else.

## Note to self: adding a new linux machine
```
nix --experimental-features 'nix-command flakes' run home-manager/master -- --experimental-features 'nix-command flakes' switch --flake .#simon-linux
atuin login
```

## Steps to setup nix-darwin on a new machine

- `nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/repos/jv-nix-config`
- After that: `darwin-rebuild switch --flake ~/repos/jv-nix-config`

## Steps to setup home-manager on a new machine

Setting this up can be a bit confusing. Nix will build all of its own packages in `/nix` and symlink them to the right place. It will also create config files like "~/.zshrc". The nix language is often described as "json with functions". The docs and examples can sometimes be confusing. For me the deterministic and portable nature of my home directory is worth the learning curve. It's quite a cool system!

- Install Nix using the Determinate Systems installer: https://github.com/DeterminateSystems/nix-installer
- Clone this configuration repository to `~/repos/jv-nix-config`
- Initialiase home-manager from the config repository: `nix --experimental-features 'nix-command flakes' run home-manager/master -- init --switch`
- Enable your configuration: `home-manager switch --flake /Users/job/repos/jv-nix-config#job-mac-intel` (in my case config-name is either job-mac-intel or job-linux)
- You will probably get some errors that either tell you what to do or you can solve them by googling (e.g. needing to run the command with  `--experimental-features 'nix-command flakes'` the first time or that you need to move `~/.zshrc` because it will now be managed by home-manager)

## Links that helped me

- [Setting up your dotfiles with home-manager as a flake · Chris Portela](https://www.chrisportela.com/posts/home-manager-flake/)
- [home-manager](https://nix-community.github.io/home-manager/)
- [Nix language basics — nix.dev documentation](https://nix.dev/tutorials/nix-language)
- [Flakes - NixOS Wiki](https://nixos.wiki/wiki/Flakes)
- [GitHub - dminca/nix-config: My Nix configuration for setting up aarch64-darwin & x86\_64-darwin workstations](https://github.com/dminca/nix-config)
- [Github - Code search results - "path:home.nix"](https://github.com/search?q=path%3Ahome.nix&type=code)
