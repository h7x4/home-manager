{ config, pkgs, lib }: let

  with lib;

  cfg = config.services.openvscode-server;
  vscCfg = config.programs.vscode;
in {
  options.services.openvscode-server = {
    enable = mkEnableOption "";

    package = mkPackageOption pkgs "openvscode-server" {};

    settings = mkOption {
      default = if vscCfg.userSettings != {} then vscCfg.userSettings else {};
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
    };

    connectionToken = mkOption {
      type = with types; nullOr (either str path);
    };

    acceptLicenseTerms = mkOption {
      type = types.bool;
    };

    userDataDir = mkOption {
      type = types.str;
      default = "${config.xdg.dataDir}/openvscode-server/user";
    };

    serverDataDir = mkOption {
      type = types.str;
      default = "${config.xdg.dataDir}/openvscode-server/server";
    };

    extensions = mkOption {
      type = types.submodule ({

      });
    };


  # --host <ip-address>            The host name or IP address the server
  #                                should listen to. If not set, defaults to
  #                                'localhost'.
  # --port <port | port range>     The port the server should listen to. If 0
  #                                is passed a random free port is picked.
  #                                If a range in the format num-num is
  #                                passed, a free port from the range (end
  #                                inclusive) is selected.
  # --socket-path <path>           The path to a socket file for the server
  #                                to listen to.
  # --connection-token <token>     A secret that must be included with all
  #                                requests.
  # --connection-token-file <path> Path to a file that contains the
  #                                connection token.
  # --without-connection-token     Run without a connection token. Only use
  #                                this if the connection is secured by
  #                                other means.
  # --accept-server-license-terms  If set, the user accepts the server
  #                                license terms and the server will be
  #                                started without a user prompt.
  # --server-data-dir              Specifies the directory that server data
  #                                is kept in.
  # --telemetry-level <level>      Sets the initial telemetry level. Valid
  #                                levels are: 'off', 'crash', 'error' and
  #                                'all'. If not specified, the server will
  #                                send telemetry until a client connects,
  #                                it will then use the clients telemetry
  #                                setting. Setting this to 'off' is
  #                                equivalent to --disable-telemetry
  # --user-data-dir <dir>          Specifies the directory that user data is
  #                                kept in. Can be used to open multiple
  #                                distinct instances of Code.
  # -h --help                      Print usage.

# Troubleshooting
  # --log <level> Log level to use. Default is 'info'. Allowed values are
  #               'critical', 'error', 'warn', 'info', 'debug', 'trace',
  #               'off'.
  # -v --version  Print version.

# Extensions Management
  # --extensions-dir <dir>              Set the root path for extensions.
  # --install-extension <ext-id | path> Installs or updates an extension. The
  #                                     argument is either an extension id
  #                                     or a path to a VSIX. The identifier
  #                                     of an extension is
  #                                     '${publisher}.${name}'. Use
  #                                     '--force' argument to update to
  #                                     latest version. To install a
  #                                     specific version provide
  #                                     '@${version}'. For example:
  #                                     'vscode.csharp@1.2.3'.
  # --uninstall-extension <ext-id>      Uninstalls an extension.
  # --list-extensions                   List the installed extensions.
  # --show-versions                     Show versions of installed
  #                                     extensions, when using
  #                                     --list-extensions.
  # --category <category>               Filters installed extensions by
  #                                     provided category, when using
  #                                     --list-extensions.
  # --pre-release                       Installs the pre-release version of
  #                                     the extension, when using
  #                                     --install-extension
  # --start-server                      Start the server when installing or
  #                                     uninstalling extensions. To be used
  #                                     in combination with
  #                                     'install-extension',
  #                                     'install-builtin-extension' and
  #                                     'uninstall-extension'.







  };

  config = {
    systemd.user.services.openvscode-server = {
      Unit = {
        Description = "openvscode-server";
        After= [ "network.target" ];
      };

      Service = {
        Type = "exec";
        ExecStart = "${cfg.package}/openvscode-server";
        Restart = "always";
      };
    };
  };
}
