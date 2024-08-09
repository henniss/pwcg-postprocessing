shouldApply () {
    if [[ ${REMOVE_BRIDGES:-} == "true" ]]; then
        return 0
    fi
    return 1
}

apply () {

$ed "$mission" <<EOF
g/graphics.bridges/?{?\\
?Bridge?\\
ka\\
/}/\\
kb\\
'a,'bd\\

w
q
EOF

}