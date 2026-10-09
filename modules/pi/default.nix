{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi-coding-agent;
  jsonFormat = pkgs.formats.json { };

  agentDir = cfg.configDir;
  agentThingsDir = "${config.home.homeDirectory}/agent-things";

  # Out-of-store links keep agent-things edits live without a switch.
  linkToAgentThings = path: config.lib.file.mkOutOfStoreSymlink "${agentThingsDir}/${path}";

  mergeSettings = pkgs.writeShellApplication {
    name = "pi-merge-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ./merge-settings.sh;
  };

  declaredSettingsFile = jsonFormat.generate "pi-declared-settings.json" cfg.declaredSettings;
  previousDeclaredSettingsFile = "${config.xdg.stateHome}/pi-coding-agent/declared-settings.json";
in

{
  options.programs.pi-coding-agent.declaredSettings = lib.mkOption {
    inherit (jsonFormat) type;
    default = { };
    description = ''
      Settings deep-merged into the writable {file}`settings.json` on every
      switch. Declared keys win; keys pi writes at runtime are kept. Use this
      instead of `settings`, which makes the file read-only.
    '';
  };

  config = {
    programs.pi-coding-agent = {
      enable = true;
      # Installed from ./packages/pi-coding-agent via home.packages.
      package = null;

      declaredSettings = {
        theme = "catppuccin-frappe";
        tuiMode = "regular";
        defaultProvider = "anthropic";
        defaultModel = "claude-opus-5-5";
        defaultThinkingLevel = "high";
        defaultTools = [ "+codemode" ];
        packages = [
          "git:github.com/schpet/linear-cli@v2.1.1"
          "npm:@injaneity/pi-computer-use"
          "git:github.com/earendil-works/pi-review"
        ];
        enabledModels = [
          "openai-codex/gpt-6-astra"
          "anthropic/claude-opus-5-5"
        ];
        hideThinkingBlock = false;
        terminal.showTerminalProgress = true;
        showCacheMissNotices = true;
        treeFilterMode = "no-tools";
        warnings.anthropicExtraUsage = false;
      };

      models.providers.anthropic.modelOverrides = {
        claude-opus-5.contextWindow = 200000;
        claude-opus-5-5.contextWindow = 200000;
      };
    };

    home.sessionVariables.PI_CACHE_RETENTION = "long";

    # force: replace the hand-made files and links from before home-manager.
    home.file = {
      "${agentDir}/models.json".force = true;
      "${agentDir}/themes" = {
        source = ./themes;
        recursive = true;
        force = true;
      };
      "${agentDir}/AGENTS.md" = {
        source = linkToAgentThings ".meta/global/AGENTS.md";
        force = true;
      };
      "${agentDir}/extensions" = {
        source = linkToAgentThings "pi-extensions";
        force = true;
      };
      "${agentDir}/skills" = {
        source = linkToAgentThings "skills";
        force = true;
      };
    };

    home.activation.mergePiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe mergeSettings} \
        ${lib.escapeShellArg "${agentDir}/settings.json"} \
        ${declaredSettingsFile} \
        ${lib.escapeShellArg previousDeclaredSettingsFile}
    '';
  };
}
