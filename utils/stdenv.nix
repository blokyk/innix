{ runCommandCC, ... }: {
  run = cmd: { name, ... }: runCommandCC name {} cmd;
}
