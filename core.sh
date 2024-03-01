#! /bin/bash 

function finish {
    # Useful if run via drag-drop to prevent terminal closing.
    read -n 1 -s -p "Done, press any key"
}
trap finish EXIT

# Setup
shopt -s nocaseglob
shopt -s nocasematch

set -e
script_root="$(cygpath -a "$0")"
script_root="$(dirname "$script_root")"
[[ -d "$script_root" ]] && cd "$script_root" || exit
set +e

(
exec >&2

type sed || exit
type ed || exit
type jq || exit

)

# Colors
Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# 
cOK="${Green}OK${Color_Off}"
cSkip="${Yellow}SKIP${Color_Off}"
cError="${Red}ERROR${Color_Off}"
cInvalid="${Red}INVALID${Color_Off}"

## Broadly used variables
root="/e/SteamLibrary/steamapps/common/IL-2 Sturmovik Battle of Stalingrad"
ed="/c/cygwin64/bin/ed.exe -s -q "
PWCGInput="${root}/PWCGBoS/BoSData/Input"
PWCGCampaigns="${root}/PWCGBoS/User/Campaigns"
sds="${root}/data/Multiplayer/il2dserverCoop.sds"


# Apply scripts by default. 
shouldApply () {
    return 0
}
# Halt on errors by default
shouldHalt=true


export PWCGDEBUG=true

mission="${1}"
mission="$(cygpath -a "${mission}")"
subtitles="${mission/.mission/.eng}"
[[ -f "${mission?}" ]] || exit
missionBase="$(basename "${mission}")"
missionBase=${missionBase/.mission/}
campaign=$(echo ${missionBase} | cut -d ' ' -f 1)
echo "${mission}"
echo "${missionBase}"
echo "${campaign}"
[[ -d "${PWCGCampaigns}/${campaign}" ]] || exit

# Normally I'd just do this, but I get write errors when writing to this fd in cygwin:
# exec {chan}<> <(:)

PIPE=$(mktemp -u)
mkfifo $PIPE
exec {chan}<>$PIPE


function componentError {
    echo -e "${f}: [${cInvalid}]"
    echo "stop" >&"$chan"
}

for f in $(find components -name '*.sh' | sort -n ) ; do
    (
    result=$cSkip
    trap componentError EXIT
    set -e
    source "$f"
    
    ( type apply > /dev/null 2>&1 ) || { echo "apply not found" ; exit ;}
    set +e
    trap - EXIT
    
    name="${name:-$f}"
    if shouldApply ; then
        if apply ; then
            result=$cOK
        else
            result=$cError
            if [[ "${shouldHalt}" == true ]] ; then echo "stop" >&"$chan" ; fi
        fi
    else
        result=$cSkip
    fi
    echo -e "${name}: [${result}]"
    )
    # We can't just break or set a loop variable from within the subshell, so we use this 
    # channel to signal the stop condition in the event of an error loading a script 
    # (always halt) or when running it (can be configured to continue instead)
    read -u $chan -t 0 && break
done