{
  pkgs,
  inputs,
  ...
}: {
  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        id = 0;
        name = "home";
        isDefault = true;
        settings = {
          "browser.startup.homepage" = "https://duckduckgo.com";
          "browser.search.defaultenginename" = "ddg";
          "browser.search.order.1" = "ddg";
          "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;

          "extensions.pocket.enabled" = false;
          "extensions.screenshots.disabled" = true;

          "browser.topsites.contile.enabled" = false;
          "browser.formfill.enable" = false;

          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;

          "browser.newtabpage.activity-stream.section.highlights.rows" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;

          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        };
        search = {
          force = true;
          default = "ddg";
          order = ["ddg" "google"];
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = ["!np"];
            };
            "NixOS Wiki" = {
              urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = ["!nw"];
            };
            "bing".metaData.hidden = true;
            "google".metaData.alias = "!g";
          };
        };
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          keepassxc-browser
          ublock-origin
          darkreader
          vimium
        ];
      };
    };
  };
}
