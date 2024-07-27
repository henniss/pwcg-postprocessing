shouldApply () {
set +u
  [[ -z $VWP_RADIUS_OVERRIDE ]] && { echo "VWP_RADIUS_OVERRIDE not set" ; return 1 ; }
set -u
}


apply () {
set -eo pipefail


# Increase CZ activation radius.
$ed "$mission" > /dev/null <<EOF
g/  Name = \"CZ\";//  Zone = 20000;/\
s/  Zone = 20000;/  Zone = ${VWP_RADIUS_OVERRIDE};/\
n

w
q
EOF

return 0
}