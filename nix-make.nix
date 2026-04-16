{
  lib,
  coreutils,
  nix-frontend ? null,
  writeShellApplication,
}:
writeShellApplication {
  name = "nix-make";
  # set the nix_frontend variable at the beginning if it's been
  # specified here
  text = lib.readFile ./nix-make.sh;

  excludeShellChecks = ["SC2050"];
  runtimeInputs = [ coreutils nix-frontend ];
  runtimeEnv = {
    nix_frontend = nix-frontend.meta.mainProgram or "";
  };
}
