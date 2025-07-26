{...}: {
  # Common user configuration that can be shared across systems
  # Note: Host-specific user settings should be defined in the host configuration

  # This sets up the user structure but hosts should override specifics
  users.users.job = {
    description = "Job Visser";
    shell = "/run/current-system/sw/bin/zsh";
    # Host-specific settings like isNormalUser, extraGroups, etc.
    # should be defined in each host configuration
  };
}
