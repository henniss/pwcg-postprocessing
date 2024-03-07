set -e
resaver="${root}/bin/resaver/MissionResaver.exe"
data="${root}/data/"
set +e

shouldApply() (
    [[ "$NO_RESAVE" == true ]] && return 1
    set -e
    shopt -s nocasematch
    eval >&2
    [[ "${mission}" =~ .*\.mission$ ]] || { echo "Not a Mission" ; exit 1; }
)

apply () {
  "${resaver?}" -d "$(cygpath -a -w "${data?}")" -f "$(cygpath -a -w "${mission?}")"
}