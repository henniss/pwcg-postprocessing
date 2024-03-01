HEADING=60
AIRFIELD="HOLMSLEY SOUTH"

apply () {
    set -e
    
    echo "Adjusting wind heading for $AIRFIELD"
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