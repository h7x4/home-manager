{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ssh;

  isPath = x: builtins.substring 0 1 (toString x) == "/";

  addressPort = entry:
    if isPath entry.address
    then " ${entry.address}"
    else " [${entry.address}]:${toString entry.port}";

  unwords = builtins.concatStringsSep " ";

  bindOptions = {
    address = mkOption {
      type = types.str;
      default = "localhost";
      example = "example.org";
      description = "The address where to bind the port.";
    };

    port = mkOption {
      type = types.nullOr types.port;
      default = null;
      example = 8080;
      description = "Specifies port number to bind on bind address.";
    };
  };

  dynamicForwardModule = types.submodule {
    options = bindOptions;
  };

  forwardModule = types.submodule {
    options = {
      bind = bindOptions;

      host = {
        address = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "example.org";
          description = "The address where to forward the traffic to.";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          example = 80;
          description = "Specifies port number to forward the traffic to.";
        };
      };
    };
  };

  matchBlockModule = types.submodule ({ dagName, ... }: {
    options = {
      host = mkOption {
        type = types.str;
        example = "*.example.org";
        description = ''
          The host pattern used by this conditional block.
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Specifies port number to connect on remote host.";
      };

      forwardAgent = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Whether the connection to the authentication agent (if any)
          will be forwarded to the remote machine.
        '';
      };

      forwardX11 = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies whether X11 connections will be automatically redirected
          over the secure channel and <envar>DISPLAY</envar> set.
        '';
      };

      forwardX11Trusted = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies whether remote X11 clients will have full access to the
          original X11 display.
        '';
      };

      identitiesOnly = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies that ssh should only use the authentication
          identity explicitly configured in the
          <filename>~/.ssh/config</filename> files or passed on the
          ssh command-line, even if <command>ssh-agent</command>
          offers more identities.
        '';
      };

      identityFile = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [];
        apply = p:
          if p == null then []
          else if isString p then [p]
          else p;
        description = ''
          Specifies files from which the user identity is read.
          Identities will be tried in the given order.
        '';
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specifies the user to log in as.";
      };

      hostname = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specifies the real host name to log into.";
      };

      serverAliveInterval = mkOption {
        type = types.int;
        default = 0;
        description =
          "Set timeout in seconds after which response will be requested.";
      };

      serverAliveCountMax = mkOption {
        type = types.ints.positive;
        default = 3;
        description = ''
          Sets the number of server alive messages which may be sent
          without SSH receiving any messages back from the server.
        '';
      };

      sendEnv = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Environment variables to send from the local host to the
          server.
        '';
      };

      compression = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Specifies whether to use compression. Omitted from the host
          block when <literal>null</literal>.
        '';
      };

      checkHostIP = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Check the host IP address in the
          <filename>known_hosts</filename> file.
        '';
      };

      proxyCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The command to use to connect to the server.";
      };

      proxyJump = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The proxy host to use to connect to the server.";
      };

      certificateFile = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [];
        apply = p:
          if p == null then []
          else if isString p then [p]
          else p;
        description = ''
          Specifies files from which the user certificate is read.
        '';
      };

      addressFamily = mkOption {
        default = null;
        type = types.nullOr (types.enum ["any" "inet" "inet6"]);
        description = ''
          Specifies which address family to use when connecting.
        '';
      };

      localForwards = mkOption {
        type = types.listOf forwardModule;
        default = [];
        example = literalExpression ''
          [
            {
              bind.port = 8080;
              host.address = "10.0.0.13";
              host.port = 80;
            }
          ];
        '';
        description = ''
          Specify local port forwardings. See
          <citerefentry>
            <refentrytitle>ssh_config</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for <literal>LocalForward</literal>.
        '';
      };

      remoteForwards = mkOption {
        type = types.listOf forwardModule;
        default = [];
        example = literalExpression ''
          [
            {
              bind.port = 8080;
              host.address = "10.0.0.13";
              host.port = 80;
            }
          ];
        '';
        description = ''
          Specify remote port forwardings. See
          <citerefentry>
            <refentrytitle>ssh_config</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for <literal>RemoteForward</literal>.
        '';
      };

      dynamicForwards = mkOption {
        type = types.listOf dynamicForwardModule;
        default = [];
        example = literalExpression ''
          [ { port = 8080; } ];
        '';
        description = ''
          Specify dynamic port forwardings. See
          <citerefentry>
            <refentrytitle>ssh_config</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for <literal>DynamicForward</literal>.
        '';
      };

      extraOptions = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra configuration options for the host.";
      };
    };

    config.host = mkDefault dagName;
  });

  matchBlockStr = cf: concatStringsSep "\n" (
    ["Host ${cf.host}"]
    ++ optional (cf.port != null)            "  Port ${toString cf.port}"
    ++ optional (cf.forwardAgent != null)    "  ForwardAgent ${lib.hm.booleans.yesNo cf.forwardAgent}"
    ++ optional cf.forwardX11                "  ForwardX11 yes"
    ++ optional cf.forwardX11Trusted         "  ForwardX11Trusted yes"
    ++ optional cf.identitiesOnly            "  IdentitiesOnly yes"
    ++ optional (cf.user != null)            "  User ${cf.user}"
    ++ optional (cf.hostname != null)        "  HostName ${cf.hostname}"
    ++ optional (cf.addressFamily != null)   "  AddressFamily ${cf.addressFamily}"
    ++ optional (cf.sendEnv != [])           "  SendEnv ${unwords cf.sendEnv}"
    ++ optional (cf.serverAliveInterval != 0)
      "  ServerAliveInterval ${toString cf.serverAliveInterval}"
    ++ optional (cf.serverAliveCountMax != 3)
      "  ServerAliveCountMax ${toString cf.serverAliveCountMax}"
    ++ optional (cf.compression != null)     "  Compression ${lib.hm.booleans.yesNo cf.compression}"
    ++ optional (!cf.checkHostIP)            "  CheckHostIP no"
    ++ optional (cf.proxyCommand != null)    "  ProxyCommand ${cf.proxyCommand}"
    ++ optional (cf.proxyJump != null)       "  ProxyJump ${cf.proxyJump}"
    ++ map (file: "  IdentityFile ${file}") cf.identityFile
    ++ map (file: "  CertificateFile ${file}") cf.certificateFile
    ++ map (f: "  LocalForward" + addressPort f.bind + addressPort f.host) cf.localForwards
    ++ map (f: "  RemoteForward" + addressPort f.bind + addressPort f.host) cf.remoteForwards
    ++ map (f: "  DynamicForward" + addressPort f) cf.dynamicForwards
    ++ mapAttrsToList (n: v: "  ${n} ${v}") cf.extraOptions
  );

in

{
  meta.maintainers = [ maintainers.rycee ];

  options.programs.ssh = {
    enable = mkEnableOption "SSH client configuration";

    forwardAgent = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether the connection to the authentication agent (if any)
        will be forwarded to the remote machine.
      '';
    };

    compression = mkOption {
      default = false;
      type = types.bool;
      description = "Specifies whether to use compression.";
    };

    serverAliveInterval = mkOption {
      type = types.int;
      default = 0;
      description = ''
        Set default timeout in seconds after which response will be requested.
      '';
    };

    serverAliveCountMax = mkOption {
      type = types.ints.positive;
      default = 3;
      description = ''
        Sets the default number of server alive messages which may be
        sent without SSH receiving any messages back from the server.
      '';
    };

    knownHosts = mkOption {
      default = {};
      type = types.attrsOf (types.submodule ({ name, config, options, ... }: {
        options = {
          certAuthority = mkOption {
            type = types.bool;
            default = false;
            description = ''
              This public key is an SSH certificate authority, rather than an
              individual host's key.
            '';
          };
          hostNames = mkOption {
            type = types.listOf types.str;
            default = [ name ] ++ config.extraHostNames;
            defaultText = literalExpression "[ ${name} ] ++ config.${options.extraHostNames}";
            description = ''
              A list of host names and/or IP numbers used for accessing
              the host's ssh service. This list includes the name of the
              containing knownHosts attribute by default
              for convenience. If you wish to configure multiple host keys
              for the same host use multiple `knownHosts`
              entries with different attribute names and the same
              `hostNames` list.
            '';
          };
          extraHostNames = mkOption {
            type = types.listOf types.str;
            default = [];
            description = ''
              A list of additional host names and/or IP numbers used for
              accessing the host's ssh service. This list is ignored if
              <option>programs.ssh.knownHosts.‹name?›.hostNames</option> is set explicitly.
            '';
          };
          publicKey = mkOption {
            default = null;
            type = types.nullOr types.str;
            example = "ecdsa-sha2-nistp521 AAAAE2VjZHN...UEPg==";
            description = ''
              The public key data for the host. You can fetch a public key
              from a running SSH server with the <command>ssh-keyscan</command>
              command. The public key should not include any host names, only
              the key type and the key itself.
            '';
          };
          publicKeyFile = mkOption {
            default = null;
            type = types.nullOr types.path;
            description = ''
              The path to the public key file for the host. The public
              key file is read at build time and saved in the Nix store.
              You can fetch a public key file from a running SSH server
              with the <command>ssh-keyscan</command> command. The content
              of the file should follow the same format as described for
              the <option>program.ssh.knownHosts.‹name?›.publicKey</option> option.
              Only a single key is supported. If a host has multiple keys,
              use <option>programs.ssh.knownHostsFiles</option> instead.
            '';
          };
          hashSalt = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = ''
              A base64 encoded random 160-bit string to use as a salt
              for hashing the hostname. If this is not specified,
              the host will not be hashed in the output file.

              It can be generated by running <command>TODO:</command>
            '';
          };
        };
      }));
      description = ''
        The set of system-wide known SSH hosts. To make simple setups more
        convenient the name of an attribute in this set is used as a host name
        for the entry. This behaviour can be disabled by setting
        <option>programs.ssh.knownHosts.‹name?›.hostNames</option> explicitly.
        You can use <option>programs.ssh.knownHosts.‹name?›.extraHostNames</option>
        to add additional host names without disabling this default.
      '';
      example = literalExpression ''
        {
          myhost = {
            extraHostNames = [ "myhost.mydomain.com" "10.10.1.4" ];
            publicKeyFile = ./pubkeys/myhost_ssh_host_dsa_key.pub;
          };
          "myhost2.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIRuJ8p1Fi+m6WkHV0KWnRfpM1WxoW8XAS+XvsSKsTK";
          "myhost2.net/dsa" = {
            hostNames = [ "myhost2.net" ];
            publicKeyFile = ./pubkeys/myhost2_ssh_host_dsa_key.pub;
          };
        }
      '';
    };

    hashKnownHosts = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Indicates that
        <citerefentry>
          <refentrytitle>ssh</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        should hash host names and addresses when they are added to
        the known hosts file.

        Do note that this has no effect on the hosts in
        <option>programs.ssh.knownHosts</option>, which has their
        own <option>hashSalt</option> option.
      '';
    };

    knownHostsFile = mkOption {
      type = types.nullOr types.str;
      default = "~/.ssh/known_hosts";
      description = ''
        Specifies where the file generated by
        <option>programs.ssh.knownHosts</option> should be located.

        If this value is set to null while there is content in
        <option>programs.ssh.knownHosts</option>, the file will get
        included directly from the nix store.
      '';
    };

    userKnownHostsFile = mkOption {
      type = types.str;
      default = "~/.ssh/known_hosts";
      description = ''
        Specifies one or more files to use for the user host key
        database, separated by whitespace. The default is
        <filename>~/.ssh/known_hosts</filename>.
      '';
    };

    extraKnownHostsFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        Specifies the paths to any extra files to include in the
        user host key database.
      '';
    };

    controlMaster = mkOption {
      default = "no";
      type = types.enum ["yes" "no" "ask" "auto" "autoask"];
      description = ''
        Configure sharing of multiple sessions over a single network connection.
      '';
    };

    controlPath = mkOption {
      type = types.str;
      default = "~/.ssh/master-%r@%n:%p";
      description = ''
        Specify path to the control socket used for connection sharing.
      '';
    };

    controlPersist = mkOption {
      type = types.str;
      default = "no";
      example = "10m";
      description = ''
        Whether control socket should remain open in the background.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration.
      '';
    };

    extraOptionOverrides = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = ''
        Extra SSH configuration options that take precedence over any
        host specific configuration.
      '';
    };

    includes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        File globs of ssh config files that should be included via the
        <literal>Include</literal> directive.
        </para><para>
        See
        <citerefentry>
          <refentrytitle>ssh_config</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>
        for more information.
      '';
    };

    matchBlocks = mkOption {
      type = hm.types.listOrDagOf matchBlockModule;
      default = {};
      example = literalExpression ''
        {
          "john.example.com" = {
            hostname = "example.com";
            user = "john";
          };
          foo = lib.hm.dag.entryBefore ["john.example.com"] {
            hostname = "example.com";
            identityFile = "/home/john/.ssh/foo_rsa";
          };
        };
      '';
      description = ''
        Specify per-host settings. Note, if the order of rules matter
        then use the DAG functions to express the dependencies as
        shown in the example.
        </para><para>
        See
        <citerefentry>
          <refentrytitle>ssh_config</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>
        for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            # `builtins.any`/`lib.lists.any` does not return `true` if there are no elements.
            any' = pred: items: if items == [] then true else any pred items;
            # Check that if `entry.address` is defined, and is a path, that `entry.port` has not
            # been defined.
            noPathWithPort =  entry: entry.address != null && isPath entry.address -> entry.port == null;
            checkDynamic = block: any' noPathWithPort block.dynamicForwards;
            checkBindAndHost = fwd: noPathWithPort fwd.bind && noPathWithPort fwd.host;
            checkLocal = block: any' checkBindAndHost block.localForwards;
            checkRemote = block: any' checkBindAndHost block.remoteForwards;
            checkMatchBlock = block: all (fn: fn block) [ checkLocal checkRemote checkDynamic ];
          in any' checkMatchBlock (map (block: block.data) (builtins.attrValues cfg.matchBlocks));
        message = "Forwarded paths cannot have ports.";
      }
      {
        assertion = !(cfg.knownHostsFile != null && builtins.elem cfg.knownHostsFile cfg.extraKnownHostsFiles);
        message = ''
          The name of the declarative knownHostsFile 'programs.ssh.knownHostsFile'
          should not be included in 'programs.ssh.extraKnownHostsFiles'.
        '';
      }
    ];

    warnings = optional (cfg.userKnownHostsFile or false) ''
      Using 'programs.ssh.userKnownHostsFile' has been deprecated and
      will be removed in the future. Please change to overriding the package
      configuration using 'programs.firefox.package' instead. You can refer to
      its example for how to do this.
    '';

    home.file.".ssh/config".text =
      let
        sortedMatchBlocks = hm.dag.topoSort cfg.matchBlocks;
        sortedMatchBlocksStr = builtins.toJSON sortedMatchBlocks;
        matchBlocks =
          if sortedMatchBlocks ? result
          then sortedMatchBlocks.result
          else abort "Dependency cycle in SSH match blocks: ${sortedMatchBlocksStr}";
      in ''
      ${concatStringsSep "\n" (
        (mapAttrsToList (n: v: "${n} ${v}") cfg.extraOptionOverrides)
        ++ (optional (cfg.includes != [ ]) ''
          Include ${concatStringsSep " " cfg.includes}
        '')
        ++ (map (block: matchBlockStr block.data) matchBlocks)
      )}

      Host *
        ForwardAgent ${lib.hm.booleans.yesNo cfg.forwardAgent}
        Compression ${lib.hm.booleans.yesNo cfg.compression}
        ServerAliveInterval ${toString cfg.serverAliveInterval}
        ServerAliveCountMax ${toString cfg.serverAliveCountMax}
        HashKnownHosts ${lib.hm.booleans.yesNo cfg.hashKnownHosts}
        UserKnownHostsFile ${cfg.userKnownHostsFile}
        ControlMaster ${cfg.controlMaster}
        ControlPath ${cfg.controlPath}
        ControlPersist ${cfg.controlPersist}

        ${replaceStrings ["\n"] ["\n  "] cfg.extraConfig}
    '';

    home.file.".ssh/known_hosts" =
      lib.mkIf (cfg.knownHosts != { }) {
      text = let
        knownHostToString = host: assert host.hostNames != [];
        if (cfg.hashKnownHosts) then
          optionalString h.certAuthority "@cert-authority "
          + concatStringsSep "," h.hostNames + " "
        else
        optionalString h.certAuthority "@cert-authority "
          + concatStringsSep "," h.hostNames + " "
          + (if h.publicKey != null then h.publicKey else readFile h.publicKeyFile);

      in (flip (concatMapStringsSep "\n") cfg.knownHosts
        (h: assert h.hostNames != [];
          optionalString h.certAuthority "@cert-authority " + concatStringsSep "," h.hostNames + " "
          + (if h.publicKey != null then h.publicKey else readFile h.publicKeyFile)
        )) + "\n";
    };
  };
}
