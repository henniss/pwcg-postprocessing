
# This script is non-essential and failure shouldn't break anything.
shouldHalt=false


apply () {
    set -e
    
    AL="${PWCGInput}/${MAP}/AirfieldLocations.json"
    echo "${PWCGInput}"
    echo "${MAP}"
    AL=$(echo "${AL}" | tr -d '\n\r')
    [[ -f "$AL" ]] || { echo "can't find '$AL'"; return 1 ; }
    
    HEADING=$(cat "$AL" | jq ".locations | map(select(.name == \"${HOMEBASE?}\")) | first.orientation.yOri")
    HEADING=$(printf "%.0f\n" $HEADING)
    echo "Adjusting wind heading for $HOMEBASE"
    echo "Take-Off Heading $HEADING"

    if [[ $(( $RANDOM % 100 )) -lt 70 ]]; then
      echo "Selecting wind from narrow cone"
      base=$(($HEADING + 135))
      new=$((($base + ($RANDOM % 90)) % 360))
    else
      echo "Selecting wind from wide cone"
      base=$(($HEADING + 90))
      new=$((($base + ($RANDOM % 180)) % 360))
    fi
    echo "New wind heading: $new"
    $ed "$mission" <<EOF
/WindLayers/
ka
'a+2,'a+6s/:.*:/:    $new :/
w
q
EOF
}