shouldApply () {
    [[ "$MAP" == "normandy" ]] || return 1 && return 0
}

apply () {
    
  sed -i -re 's/GuiMap = .*;/GuiMap = "normandy-summer";/' "${mission}"

}