
# This script is non-essential and failure shouldn't break anything.
shouldHalt=false


apply () {
    
    tempfile=$(mktemp)
    
    AL="${PWCGInput}/${PWCGMAP}/AirfieldLocations.json"
    [[ -f "$AL" ]] || { echo "can't find '$AL'"; return 1 ; }
    
    for var in HOMEBASE PWCGMAP; do
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
'a+2W $tempfile

w
q
EOF


    speed=$(cat $tempfile | sed -e 's/.*:.*:[[:space:]]*\([[:digit:]]*\);.*/\1/')
    echo "${new@Q} ${speed@Q}"
    dir=$((($new + 180) % 360))
    briefing_text=$(perl -e "printf '<br><br>Wind: to %d at %d m\/s', $dir, $speed")
    
    echo "${briefing_text@Q}"
    
    echo "----"
#    | 
    cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | sed -e "2s/\r$/$briefing_text\r/" | iconv -f "UTF-8" -t "UTF-16LE"  > "$tempfile"
    mv "$tempfile" "$subtitles"

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