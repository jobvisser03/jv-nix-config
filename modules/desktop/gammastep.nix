# Gammastep color temperature configuration
# Home-manager module for automatic blue light reduction
{...}: {
  flake.modules.homeManager.gammastep = {
    ...
  }: {
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = 52.37;
      longitude = 4.90;
      temperature = {
        day = 6500;
        night = 3700;
      };
      settings = {
        general = {
          adjustment-method = "wayland";
          fade = 1;
        };
      };
    };
  };
}
