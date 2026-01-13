{...}: {
  services.keyd = {
    enable = true;
    settings = {
      main = {
        # Maps the Super key (meta) to Control
        meta = "layer(control)";
      };
    };
  };
}
