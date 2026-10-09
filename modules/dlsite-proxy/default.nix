{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.dlsiteProxy;
  logDir = "${config.home.homeDirectory}/Library/Logs";
  socksPort = 10808;

  # Import from derivation: Nix builds dlbooster-bootstrap, then reads its output.
  bootstrap = lib.importJSON "${pkgs.callPackage ./dlbooster-bootstrap.nix { }}/bootstrap.json";

  # "*.dlsite.com" -> "dlsite.com"
  domains = map (lib.removePrefix "*.") bootstrap.upstreams.rules;

  # "vm://<id>@<host>:<port>?n=<tag>#<name>" -> { id, address, port, tag }
  parseVmessRoute =
    route:
    let
      match = builtins.match "vm://([^@]+)@([^:]+):([0-9]+)\\?n=([^#&]+).*" route;
    in
    if match == null then
      throw "dlsite-proxy: cannot parse DLBooster route: ${route}"
    else
      {
        id = builtins.elemAt match 0;
        address = builtins.elemAt match 1;
        port = lib.toInt (builtins.elemAt match 2);
        tag = builtins.elemAt match 3;
      };

  vmessServers = map parseVmessRoute bootstrap.upstreams.routes;

  xrayConfig = (pkgs.formats.json { }).generate "xray.json" {
    log.loglevel = "warning";
    inbounds = [
      {
        tag = "socks-in";
        listen = "127.0.0.1";
        port = socksPort;
        protocol = "socks";
        settings = {
          auth = "noauth";
          udp = false;
        };
      }
    ];
    outbounds =
      map (server: {
        inherit (server) tag;
        protocol = "vmess";
        settings.vnext = [
          {
            inherit (server) address port;
            users = [
              {
                inherit (server) id;
                security = "auto";
              }
            ];
          }
        ];
      }) vmessServers
      ++ [
        {
          tag = "block";
          protocol = "blackhole";
        }
      ];
    # Measure each server so the balancer can pick the fastest one.
    observatory = {
      subjectSelector = map (server: server.tag) vmessServers;
      probeUrl = "https://www.dlsite.com/cdn-cgi/trace";
      probeInterval = "5m";
      enableConcurrency = true;
    };
    routing = {
      domainStrategy = "AsIs";
      balancers = [
        {
          tag = "japan";
          selector = map (server: server.tag) vmessServers;
          strategy.type = "leastPing";
          fallbackTag = (builtins.head vmessServers).tag;
        }
      ];
      rules = [
        {
          type = "field";
          domain = map (domain: "domain:${domain}") domains;
          balancerTag = "japan";
        }
        # Privoxy sends only the domains above here. Block everything else.
        {
          type = "field";
          network = "tcp,udp";
          outboundTag = "block";
        }
      ];
    };
  };

  # ".example.com" matches example.com and all of its subdomains.
  # The last matching forward rule wins, so these override "forward / .".
  privoxyConfig = pkgs.writeText "privoxy.conf" ''
    listen-address 127.0.0.1:${toString cfg.httpPort}

    toggle 1
    enable-remote-toggle 0
    enable-edit-actions 0
    socket-timeout 300

    # Connect directly by default.
    forward / .
    ${lib.concatMapStringsSep "\n" (
      domain: "forward-socks5t .${domain}/ 127.0.0.1:${toString socksPort} ."
    ) domains}
  '';

  launchdAgent = name: programArguments: extraConfig: {
    enable = true;
    config = {
      ProgramArguments = programArguments;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/${name}.log";
      StandardErrorPath = "${logDir}/${name}.log";
    }
    // extraConfig;
  };
in

{
  options.services.dlsiteProxy = {
    enable = lib.mkEnableOption "an HTTP proxy that routes DLsite through DLBooster's Japanese servers";

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 8118;
      description = "Port on 127.0.0.1 where Privoxy accepts HTTP proxy connections.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.dlsiteProxy" pkgs lib.platforms.darwin)
    ];

    launchd.agents.privoxy =
      launchdAgent "privoxy"
        [
          "${pkgs.privoxy}/bin/privoxy"
          "--no-daemon"
          "${privoxyConfig}"
        ]
        {
          ProcessType = "Background";
          ThrottleInterval = 5;
        };

    launchd.agents.xray =
      launchdAgent "xray"
        [
          "${pkgs.xray}/bin/xray"
          "run"
          "-c"
          "${xrayConfig}"
        ]
        {
          ThrottleInterval = 30; # Wait 30 s between restarts if Xray keeps exiting
        };
  };
}
