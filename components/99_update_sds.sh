apply () {
    mission_dir="$(dirname "${mission}")"
    base="${root}/data/Multiplayer/"
    rel="$(realpath --relative-to="${base}" "${mission}")"
    
    if (( 0 == $(find "$base" -wholename "$mission" | wc -l) )) ; then 
        return 1
    fi

    goal="$(cygpath -w "${rel%.*}")"
    goal="$(echo "$goal" | sed -e 's|\\|\\\\|')"
    echo "goal: $goal"

    sed -i -re "s/.*file =.*/    file = \"$goal\"/" "$sds2"

    IP=$(ipconfig | grep "IPv4 Address" | cut -d ':' -f 2 | tr -d ' ' | grep -v "192\.168\..*")
    if [[ -n "$IP" ]]; then
      echo "$IP"
      sed -i -re "s/ServerIP.*/ServerIP = \"$IP\"/" "$sds"
    fi

    mkdir -p "${mission_dir}/trash"
    mv "$mission" "${mission_dir}/trash"
}