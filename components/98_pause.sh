
shouldApply () {
    echo "PAUSE_FOR_EDITS: ${PAUSE_FOR_EDITS:-}"
    if [[ -z ${PAUSE_FOR_EDITS+x} ]]; then
        return 1
    fi
    return 0
}

apply () {
    read -n 1 -s -p "Paused for manual edits. Press any key to continue."
}