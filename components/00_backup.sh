shopt -s nocasematch
shopt -s nocaseglob
mdir="$(dirname "${mission}")"
backups="$(dirname "${mission}")"/backups

shouldApply() {
    [[ -f "${backups}/$(basename "${mission}")" ]] && return 1
    return 0
}

apply() {
    mkdir -p "${backups}"
    cp -n "${mdir}/${missionBase}".* "${backups}"
}