{ lib
, mkShell
, runCommandLocal
, pre-commit
, yq-go
,
}:
let
  mkConfig = config:
    let
      # Load module and evaluate against passed configuration
      mod = lib.evalModules {
        modules = [
          ./modules/hook.nix
          {
            inherit config;
          }
        ];
      };

      # Get list of unique values for hook attr in all repos
      hook_attrs = attr:
        lib.unique (
          lib.flatten (
            builtins.map
              (
                repo:
                builtins.filter (value: value != null) (
                  builtins.map (builtins.getAttr attr) repo.hooks
                )
              )
              mod.config.repos
          )
        );

      # List of all referenced packages
      packages = (hook_attrs "package") ++ [ pre-commit ];

      # Create a YAML variant of the generated configuration. Most default values
      # are null, so they are filtered from the final configuration. This keeps it
      # small and prevents drift by enforcing default values provided by `pre-commit`.
      configFile =
        runCommandLocal "pre-commit-config.yaml"
          {
            buildInputs = [ yq-go ];
            json = builtins.toJSON {
              repos =
                let
                  filterAttrs = lib.filterAttrs (name: value: name != "package" && value != null);
                in
                builtins.map
                  (
                    repo:
                    (filterAttrs repo)
                    // {
                      hooks = builtins.map filterAttrs repo.hooks;
                    }
                  )
                  mod.config.repos;
            };
            passAsFile = [ "json" ];
          }
          "yq --prettyPrint < $jsonPath > $out";

      # Provides a shell hook for linking the generated configuration and installing
      # the required git hook scripts. Changes are only applied when the
      # configuration changes.
      shellHook = ''
        configFile=${configFile}
        installStages=${builtins.concatStringsSep " " ((hook_attrs "stages") ++ ["pre-commit"])}
        pre_commit=${pre-commit}/bin/pre-commit
        source ${./shell-hook.sh}
      '';
    in
    {
      inherit packages shellHook;
      devShell = mkShell {
        inherit packages shellHook;
      };
    };
in
{
  inherit mkConfig;

  # make a config with single local repo
  mkLocalConfig = hooks: (mkConfig {
    repos = [
      {
        repo = "local";
        inherit hooks;
      }
    ];
  });
}
