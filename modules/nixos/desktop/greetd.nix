# Greetd display manager configuration
{lib, ...}: {
  flake.modules.nixos.greetd = {
    config,
    pkgs,
    ...
  }: {
    services.displayManager.defaultSession = "hyprland";

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --asterisks --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # Create greeter user
    users.users.greeter = {
      isNormalUser = false;
      description = "greetd greeter user";
      extraGroups = ["video" "audio"];
      linger = true;
    };
  };
}
