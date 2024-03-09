base="${root}/data/Multiplayer/"

shouldApply () {
    if (( 0 == $(find "$base" -wholename "$mission" | wc -l) )) ; then 
        return 1
    fi
}

apply () {
    mission_dir="$(dirname "${mission}")"
    rel="$(realpath --relative-to="${base}" "${mission}")"
    

    goal="$(cygpath -w "${rel%.*}")"
    goal="$(echo "$goal" | sed -e 's|\\|\\\\|')"
    echo "goal: $goal"

    sed -i -re "s/.*file =.*/    file = \"$goal\"/" "$sds"

    IP=$(ipconfig | grep "IPv4 Address" | cut -d ':' -f 2 | tr -d ' ' | grep -v "192\.168\..*" | head -n 1)
    if [[ -z "$IP" ]]; then 
        IP=$(ipconfig | grep "IPv4 Address" | cut -d ':' -f 2 | tr -d ' ' | grep "192\.168\..*" | head -n 1)
    fi
    
    echo "IP: $IP"
    sed -i -re "s/ServerIP.*/ServerIP = \"$IP\"/" "$sds"
    
    mkdir -p "${mission_dir}/trash"
    mv "$mission" "${mission_dir}/trash"
}