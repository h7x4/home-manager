{ config }: let

  with lib; 

  cfg = config.services.plank;
in {
  # https://github.com/nix-community/home-manager/issues/3180
  meta.maintainers = with maintainers; [ h7x4 ];
  options.services.plank = {
    enable = mkEnableOption "twmn, a tiling window manager notification daemon";

        extraConfig = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression
        ''{ main.activation_command = "\${pkgs.hello}/bin/hello"; }'';
      description = ''
        Extra configuration options to add to the twmnd config file. See
        <link xlink:href="https://github.com/sboli/twmn/blob/master/README.md"/>
        for details.
      '';
    };

    dockItems = mkOption {
      type = types.listOf (types.submodule {

      });
    }
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.plank" pkgs platforms.linux)
    ];

    home.packages = with pkgs; [ plank ];

    xdg.configFile."plank" = mkIf (cfg.dockItems != { }) let

    in ;

    systemd.user.services.twmnd = {
      Unit = {
        Description = "twmn daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers =
          [ "${config.xdg.configFile."twmn/twmn.conf".source}" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${pkgs.twmn}/bin/twmnd";
        Restart = "on-failure";
        Type = "simple";
        StandardOutput = "null";
      };
    };
  };
}
