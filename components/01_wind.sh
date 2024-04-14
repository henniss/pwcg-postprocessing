
# This script is non-essential and failure shouldn't break anything.
shouldHalt=false


apply () {
    set -e
    
    AL="${PWCGInput}/${MAP}/AirfieldLocations.json"
    [[ -f "$AL" ]] || { echo "can't find '$AL'"; return 1 ; }
    
    for var in HOMEBASE MAP; do
      if [[ -z "${!var}" ]]; then
        echo "${var} not set."
        return 1
      fi
    done
    
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

# city_fire, city_firesmall, and villagesmoke all need to be manually turned.
$ed "$mission" > /dev/null <<EOF
,g/villagesmoke/?{?\\
/YOri/\\
s/.*/  YOri = ${new}.00;

,g/city_fire/?{?\\
/YOri/\\
s/.*/  YOri = ${new}.00;

,g/city_firesmall/?{?\\
/YOri/\\
s/.*/  YOri = ${new}.00;

w
q
EOF


}