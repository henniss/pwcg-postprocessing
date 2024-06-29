shopt -s nocasematch
shopt -s nocaseglob

pcm="${PWCGCampaigns}/${campaign}/pilot-code-map.csv"
envf="${PWCGCampaigns}/${campaign}/env.sh"

shouldApply() {
    [[ -d "${PWCGCampaigns}/${campaign}" ]] && return 0
    return 1
}

apply() {
    declare -a created=()
    for f in pcm envf ; do 
        name="$(basename "${!f}")"
        [[ -f "${!f}" ]] || { created+=("${!f}") ; touch "${!f}"; }
    done
    
    if (( "${#created[@]}" > 0 )); then
        printf "Created:\n"
        for c in "${created[@]}"; do 
        printf "\t%s\n" "$(cygpath -w "${c}")"
        done
        printf "edit these to customize your campaign."
    fi
}