# nix-pre-commit

> Generate [pre-commit][1] configurations with your flake.nix

## Usage

Add it as an input to your flake and define the pre-commit configuration:

```nix
{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
    nix-pre-commit.url = "github:jmgilman/nix-pre-commit";
  };

  outputs = { self, nixpkgs, flake-utils, nix-pre-commit }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = (nix-pre-commit.lib.${system}.mkLocalConfig [
          {
            package = pkgs.nixpkgs-fmt;
            types = ["nix"];
          }
        ]) devShell;
      }
    );
}
```

This produces a `.pre-commit-config.yaml` in the local directory:

```yaml
repos:
  - hooks:
      - entry: /nix/store/l9vwl9yvjmdj3pixlj5i9kc4524bh78r-nixpkgs-fmt-1.2.0/bin/nixpkgs-fmt
        id: nixpkgs-fmt
        language: system
        name: nixpkgs-fmt
        types:
         - nix
    repo: local
```

The structure for the configuration specified in `flake.nix` matches the
[defined structure][2] of the `.pre-commit-config.yaml` file. A small
bootstrapping script is supplied via a [shellHook][3] which links the generated
config into the local directory and installs the hooks.

### Provided Functions

#### lib.mkConfig

  Make multi-repo configuration from `config` attrset as:

  ```nix
  lib.mkConfig {
    repos = [
      {
        repo = "local";
        hooks = [
          {
            package = pkgs.nixpkgs-fmt;
          }
          { ... }
        ];
      }
      { ... }
    ];
  }
  ```

#### lib.mkLocalConfig

  Make single-repo local configuration from `hooks` list as:

  ```nix
  lib.mkLocalConfig [
    {
      package = pkgs.nixpkgs-fmt;
    }
    { ... }
  ]
  ```

#### Config Attrset

This is the return value of `lib.mkConfig` and `lib.mkLocalConfig`:

* `packages`: list of hook packages (includes pre-commit)
* `shellHook`: the shell hook
* `devShell`: convenience wrapper - `pkgs.mkShell` called with `packages` and `shellHook`

## Contributing

Check out the [issues][4] for items needing attention or submit your own and
then:

1. Fork the repo (<https://github.com/jmgilman/dev-container/fork>)
2. Create your feature branch (git checkout -b feature/fooBar)
3. Commit your changes (git commit -am 'Add some fooBar')
4. Push to the branch (git push origin feature/fooBar)
5. Create a new Pull Request

[1]: https://pre-commit.com/
[2]: https://pre-commit.com/#pre-commit-configyaml---hooks
[3]: https://nixos.org/manual/nix/stable/command-ref/nix-shell.html#description
[4]: https://github.com/jmgilman/nix-pre-commit/issues
