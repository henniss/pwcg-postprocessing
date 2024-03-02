# As we rework this...
# basically iterate over every pilot in the pilot code map
# if they're dead, remove them. 
# if they're alive, keep them.
# then make a list of unused codes
# for every pilot in the file, if present, use it, otherwise add them to the map with a new code.
shouldHalt=false

PCM="${PWCGCampaigns}/${campaign}/pilot-code-map.csv"
SP="${PWCGCampaigns}/${campaign}/Personnel/${squadcode}.json"

tempfile="tac_code_scratch.txt"

shouldApply () {
# todo squadcode
for v in campaign ; do 
    [[ -n "${!v}" ]] || { echo "$v unset" ; return 1 ; }
done
[[ -f "$PCM" ]] || { echo "can't find '$PCM'"; return 1 ; }
}


apply () {
set -e

sed -i -e '$a\' "$PCM"

rm -f "$tempfile"

# enumerate pilots.
edscript="/Flight $unit/
ka
/Name = \"Flight/
kb
'a,'bg/LuaScripts.WorldObjects.Planes/kc\\
/}/\\
kd\\
'c\\
/Name =/\\
.W $tempfile\\


q
"

echo -e "$edscript" | $ed "$mission" > /dev/null

names="$(sed -nE 's/\s*Name\s*=\s*"Flt O\s(.*)";/\1/p' "$tempfile")"

while read -r name ; do
code=$(echo "$code" | tr -d '\n\r')
if ! grep -q "$name" "$PCM"; then
    echo "Pilot not configured: $name." 
    error=1
fi
done <<< "$names"

if [[ -n "$error" ]]; then
echo "Exiting"
read -s -n 1
sleep 1
exit 1
fi


while IFS=, read name model code; do
if ! grep -q "$name" "$tempfile"; then
    continue
fi
code=$(echo "$code" | tr -d '\n\r')
fullcode="$(printf "$tac_code_pattern" "$code" "$code")"
echo "$name: $fullcode"
edscript="/Name = \".*$name\";/
?Plane?
ka
n
/}/
kb
n
'a,'bg/TCode \=/s/\".*\";/\"$fullcode\";/
'a,'bg/TCodeColor/s/\"111\"/\"1111\"/
w
q
"
echo "$edscript" | $ed "$mission" > /dev/null
done <"$PCM"
}

