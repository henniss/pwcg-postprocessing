shouldApply () {
    return 0
}

apply () {
    sed -i -re 's/Spotter = .*;/Spotter = -1;/' "${mission}"
}