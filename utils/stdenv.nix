{ runCommandWith, stdenv, ... }: {
  run = cmd: { name, derivationArgs, ... }:
    runCommandWith {
      inherit name stdenv derivationArgs;
      runLocal = true;
    } cmd;
  runRemote = cmd: { name, derivationArgs, ... }:
    runCommandWith {
      inherit name stdenv derivationArgs;
      runLocal = false;
    } cmd;
}
