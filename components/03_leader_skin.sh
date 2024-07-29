shouldHalt=false

shouldApply () {
# todo squadcode
set +u
for v in leader_skin_override leader_tcode_override; do 
    [[ -n "${!v}" ]] || { echo "$v unset" ; return 1 ; }
done
}


apply () {
set -e



PLAYER_FLIGHT=$(echo "$PLAYER_FLIGHT" | tr '/' '.')

$ed "$mission"  <<EOF
/Flight ${PLAYER_FLIGHT}/
/LuaScripts.WorldObjects.Planes/n
?Plane?n
ka
/}/n
kb
/TCode/n
'a
/Skin/n
'a,'bg/TCode[[:space:]]/s/".*";/"$leader_tcode_override";/
'a,'bg/Skin[[:space:]]/s/".*";/"$leader_skin_override";/
w
q
EOF
}

