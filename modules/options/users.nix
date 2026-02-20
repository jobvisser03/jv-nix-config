# Define users as top-level config - accessible everywhere via config.my.users
{lib, ...}: {
  options.my.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        username = lib.mkOption {
          type = lib.types.str;
          description = "System username";
        };
        homeDirectory = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          description = "Home directory by platform (linux/darwin)";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Email address for git etc";
        };
      };
    });
    default = {};
    description = "User definitions";
  };

  config.my.users = {
    personal = {
      username = "job";
      homeDirectory = {
        linux = "/home/job";
        darwin = "/Users/job";
      };
      email = "job@dutchdataworks.com";
    };
    work = {
      username = "job.visser";
      homeDirectory = {
        darwin = "/Users/job.visser";
      };
      email = "job@dutchdataworks.com";
    };
  };
}
