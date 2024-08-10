
shouldApply () {
    if [[ ${PAUSE_FOR_EDITS:-} == "true" ]]; then
        return 0
    fi
    return 1
}

apply () {
    read -n 1 -s -p "Paused for manual edits. Press any key to continue."
}