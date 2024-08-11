
shouldApply () {
    if [[ ${DEBUG:-} != "true" ]]; then
        return 0
    fi
    return 1
}

apply () {
$ed "$mission" <<EOF
,g/Name = "DEBUG";/?{?\\
ka\\
n\\
/^}/\\
kb\\
n\\
'a,'bs/Enabled *=.*/Enabled = 0;/

w
q
EOF
}