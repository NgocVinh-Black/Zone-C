{ self, ... }:
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zone-c;
  system = pkgs.stdenv.hostPlatform.system;

  jsonFormat = pkgs.formats.json { };
  inherit (import ./settings-options.nix { inherit lib pkgs; }) settingsSubmodule;

  templateSettings = builtins.fromJSON (builtins.readFile "${self}/config/zone-c/settings.json");

  userSettings = lib.filterAttrsRecursive (_: v: v != null) cfg.settings;

  mergedSettings = lib.recursiveUpdate templateSettings userSettings;
  settingsFile = jsonFormat.generate "zone-c-settings.json" mergedSettings;

  settingsTarget = "${config.xdg.configHome}/zone-c/settings.json";
in
{
  options.programs.zone-c = {
    enable = mkEnableOption "the Zone-C Quickshell desktop shell";

    package = mkOption {
      type = types.package;
      default = self.packages.${system}.default;
      defaultText = literalExpression "zone-c.packages.<system>.default";
      description = "The Zone-C package to use.";
    };

    settings = mkOption {
      type = settingsSubmodule;
      default = { };
      example = literalExpression ''
        {
          bar.position = "left";
          bar.modules.right = [ "tray" [ "kb" "wifi" "bt" "vol" "bat" ] ];
          theme.fontFamily = "Adwaita Mono";
          notifications.dnd = true;
        }
      '';
      description = ''
        Zone-C configuration, layered on top of the package's
        bundled `config/zone-c/settings.json` and written to
        `$XDG_CONFIG_HOME/zone-c/settings.json`.
        See settings-options.nix for the full list of typed fields;
        anything not listed there can still be set as a plain
        attribute.
      '';
    };

    systemd = {
      enable = mkOption {
        type = types.bool;
        default = pkgs.stdenv.isLinux;
        description = "Whether to run zone-cd as a `systemd --user` service.";
      };

      target = mkOption {
        type = types.str;
        default = "graphical-session.target";
        description = "Target zone-cd is tied to (start/stop/restart with it).";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = { QT_QPA_PLATFORM = "wayland"; };
        description = "Extra environment variables for the zone-cd unit.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.zone-c.settings.wallpaperDir = mkDefault "${config.home.homeDirectory}/Pictures/Wallpapers";

    home.activation.zoneCSettings = hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${escapeShellArg (builtins.dirOf settingsTarget)}
      if [ ! -e ${escapeShellArg settingsTarget} ]; then
        run install -m 0644 ${settingsFile} ${escapeShellArg settingsTarget}
      fi
    '';

    systemd.user.services.zone-c = mkIf cfg.systemd.enable {
      Unit = {
        Description = "Zone-C shell daemon";
        After = [ cfg.systemd.target ];
        PartOf = [ cfg.systemd.target ];
        X-Restart-Triggers = [ "${settingsFile}" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/zone-cd start";
        Restart = "on-failure";
        KillMode = "mixed";
        TimeoutStopSec = "5s";
        Environment = mapAttrsToList (n: v: "${n}=${v}") cfg.systemd.environment;
      };

      Install.WantedBy = [ cfg.systemd.target ];
    };
  };
}
