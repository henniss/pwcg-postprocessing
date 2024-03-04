
sds2="/e/SteamLibrary/steamapps/common/IL-2 Sturmovik Battle of Stalingrad/data/Multiplayer/il2dserverCoopProxy.sds"

apply () {
    mission_dir="$(dirname "${mission}")"
    base="/e/SteamLibrary/steamapps/common/IL-2 Sturmovik Battle of Stalingrad/data/Multiplayer/"
    rel="$(realpath --relative-to="${base}" "${mission}")"

    goal="$(cygpath -w "${rel%.*}")"
    goal="$(echo "$goal" | sed -e 's|\\|\\\\|')"
    echo "goal: $goal"

    sed -i -re "s/.*file =.*/    file = \"$goal\"/" "$sds2"

    IP=$(ipconfig | grep "IPv4 Address" | cut -d ':' -f 2 | tr -d ' ' | grep -v "192\.168\..*")
    if [[ -n "$IP" ]]; then
      echo "$IP"
      sed -i -re "s/ServerIP.*/ServerIP = \"$IP\"/" "$sds2"
    fi

    mkdir -p "${mission_dir}/trash"
    mv "$mission" "${mission_dir}/trash"
}