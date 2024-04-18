#! /bin/bash 
set -u

function finish {
    # Useful if run via drag-drop to prevent terminal closing.
    read -n 1 -s -p "Done, press any key to exit."
}
trap finish EXIT

###########################################
### MODIFY THESE VARIABLES FOR YOUR INSTALL
###########################################
root="E:\SteamLibrary\steamapps\common\IL-2 Sturmovik Battle of Stalingrad"
sds="E:\SteamLibrary\steamapps\common\IL-2 Sturmovik Battle of Stalingrad\data\Multiplayer\il2dserverCoop.sds"

root="$(cygpath -a "${root}")"
sds="$(cygpath -a "${sds}")"
PWCGInput="${root}/PWCGBoS/BoSData/Input"
PWCGCampaigns="${root}/PWCGBoS/User/Campaigns"

{
# Check that we have common dependencies. If these are installed but can't be found you may need to add your cygwin bin directory to your path.
for prog in sed ed jq iconv perl ; do 
type $prog || { echo "$prog not found" ; exit 1 ; }
done
} >&2

# Setup
shopt -s nocaseglob
shopt -s nocasematch

script_root="$(cygpath -a "$0")"
script_root="$(dirname "$script_root")"
data="$(realpath ./data)"
[[ -d "$script_root" ]] && cd "$script_root" || { echo "unable to cd to script root"; exit ; }



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

# Common fragments
cOK="${Green}OK${Color_Off}"
cSkip="${Yellow}SKIP${Color_Off}"
cError="${Red}ERROR${Color_Off}"
cInvalid="${Red}INVALID${Color_Off}"

ed="ed "

for d in root PWCGInput PWCGCampaigns ; do 
    if ! [[ -d "${!d}" ]] ; then 
        echo "not a directory: $d (${!d})"
        exit
    fi
done

for f in sds ; do 
    if ! [[ -f "${!f}" ]] ; then 
        echo "not a file: $f (${!f})"
        exit
    fi
done


# Apply scripts by default. 
shouldApply () {
    return 0
}
# Halt on errors by default
shouldHalt=true

mission="${1}"
mission="$(cygpath -a "${mission?}")"
subtitles="${mission/.mission/.eng}"
[[ -f "${mission?}" ]] || exit
missionBase="$(basename "${mission?}")"
missionBase=${missionBase/.mission/}
campaign=$(echo ${missionBase} | cut -d ' ' -f 1)
[[ -d "${PWCGCampaigns}/${campaign?}" ]] || campaign=""
echo "mission: ${mission}"
echo "missionBase: ${missionBase}"
echo "campaign: ${campaign}"

mdir="$(dirname "${mission?}")"
backups="${mdir?}/backups"
trash="${mdir?}/trash"

if { cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | grep -q "Escorted" ; } ; then
    IS_MISSION_WITH_ESCORT=true
else
    IS_MISSION_WITH_ESCORT=false
fi

PLAYER_FLIGHT=$(cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | grep "stationed at" | sed "s/.*<br>\(.*\) stationed at \([^<>]*\)<br>.*/\1/" | tr -d '\r')
ESCORT_FLIGHT=$(cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | grep "Escorted" | sed "s/.*of \(.*\)/\1/"  | tr -d '\r')
if cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | grep -q "Rendezvous with" ; then
    IS_ESCORT=true
else
    IS_ESCORT=false
fi
HOMEBASE=$(cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | grep "stationed at" | sed "s/.*<br>\(.*\) stationed at \([^<>]*\)<br>.*/\2/"  | tr -d '\r')

# TODO: 
# squadron code
# side

echo "is_escort: $IS_ESCORT"
echo "PLAYER_FLIGHT: $PLAYER_FLIGHT"
echo "ESCORT_FLIGHT: $ESCORT_FLIGHT"
echo "HOMEBASE: $HOMEBASE"
echo "IS_MISSION_WITH_ESCORT: $IS_MISSION_WITH_ESCORT"

set -e
source ./default_env.sh
envf="${PWCGCampaigns}/${campaign}/env.sh"
if [[ -f "$envf" ]] ; then
    source "$envf"
else
    echo "using default env"
fi
set +e

# normalize to lowercase
MAP="${MAP,,}"
# PWCG internal naming is inconsistent with gui map
PWCGMAP="${MAP/rheinland/bodenplatte}" # sic

printf "MAP: %q\n" "$MAP"

# Normally I'd just do this, but I get write errors when writing to this fd in cygwin:
# exec {chan}<> <(:)

PIPE=$(mktemp -u)
mkfifo $PIPE
exec {chan}<>$PIPE


componentError () {
    echo -e "${f}: [${cInvalid}]"
    echo "stop" >&"$chan"
    
    restoreBackup "${mission}"
}

makeBackup () (
    set -e
    mkdir -p "${backups}"
    cp -f "${mdir?}/${missionBase?}".* "${backups?}"
)

restoreBackup () (
    set -e
    
    [[ "true" == "${NO_RESTORE:-false}" ]] && return 0
    
    echo "restoring..."
    
    mkdir -p "${trash}"
    mv "${mdir?}/${missionBase?}".* "${trash}"
    cp -n -f "${backups?}/${missionBase?}".* "${mdir?}"
)

makeBackup "${mission}"

for f in $(find components -name '*.sh' | sort -n ) ; do
    (
    result=$cSkip
    trap componentError EXIT
    set -e
    source "$f"
    
    ( type apply > /dev/null 2>&1 ) || { echo "apply not found" ; exit ;}
    set +e
    trap - EXIT
    
    if shouldApply ; then
        if ( apply ) ; then
            result=$cOK
        else
            result=$cError
            if [[ "${shouldHalt}" == true ]] ; then
                restoreBackup "${mission}"
                echo "stop" >&"$chan" 
            fi
        fi
    else
        result=$cSkip
    fi
    echo -e "${f}: [${result}]"
    )
    # We can't just break or set a loop variable from within the subshell, so we use this 
    # channel to signal the stop condition in the event of an error loading a script 
    # (always halt) or when running it (can be configured to continue instead)
    read -u $chan -t 0 && break
done