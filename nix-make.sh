# shellcheck shell=bash

print_usage() {
    echo -e 'Usage: \x1b[1m'"$(basename "$0")"' <targets...>\x1b[0m [-f|--file <makefile>] [--shell] [--no-nom] \x1b[0;2m[nix options...]\x1b[0m'
    echo -e '\x1b[3mNote: the target names must come \x1b[1mbefore\x1b[0;3m any nix options\x1b[0m'
}

if ! [[ -v 1 ]]; then
    print_usage
    exit 1
fi

is_nom_in_path() { type "nom-build" "nom-shell" 1>/dev/null 2>/dev/null; }

# nix_frontend will be set by writeShellApplication if specified;
# but if it's not, we try to detect it based on the commands available in the path
if [[ -z "${nix_frontend:-}" ]]; then
    nix_frontend="$(is_nom_in_path && echo "nom" || echo "nix")"
fi

targets=()
nix_action="build"
makefile="./makefile.nix"
while [[ -n "${*}" ]]; do
    opt="$1"
    case "$opt" in
        --shell)
            nix_action="shell"
        ;;
        --no-nom)
            nix_frontend="nix"
        ;;
        --file|-f)
            shift
            if ! [[ -v 1 ]]; then
                echo -e '\x1b[1;31mThe --file option expects an argument\x1b[0m'
                exit 1
            fi
            makefile="$1"
        ;;
        # as soon as we encounter an option that isn't one we know,
        # treat the rest of the command line as options for nix
        -*)
            # break out of the for and DON'T shift (otherwise we'd drop an arg)
            break
        ;;
        # if this isn't one of our options *nor* a nix option,
        # then it's a target
        *)
            targets+=("$opt")
        ;;
    esac
    shift
done

if ! { [[ -f "$makefile" ]] || [[ -f "$makefile/default.nix" ]]; }; then
    echo -e "\x1b[1;31mMakefile '$makefile' doesn't exist.\x1b[0m"
    exit 1
fi

# if there were no targets
if [[ ${#targets[@]} -eq 0 ]]; then
    echo -e "\x1b[1;31mNo targets suppplied\x1b[0m"
    print_usage
    exit 1
fi

# add double-quotes around the name of each target
targets=("${targets[@]/#/'"'}")
targets=("${targets[@]/%/'"'}")

# shellcheck disable=SC2016 # shellcheck thinks nix interpolation is shell var substitution
expr='
let
  mk = import '"$(realpath "$makefile")"';
  makefileIsNotAFunc = "File '"${makefile}"' should return a function (the result of '"'"'innix.make {...}'"'"') but it'"'"'s actually a ${builtins.typeOf mk}";
in
assert builtins.isFunction mk || (mk ? __functor) || throw makefileIsNotAFunc;
map mk [ '"${targets[*]}"' ]'

exec "${nix_frontend}-${nix_action}" -E "$expr" "$@"
