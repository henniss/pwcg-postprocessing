# This finds every artillery-piece and rigs up events so that they require a bomb 
# to be destroyed.
# Bugs: It's possible to deactivate a gun while it's firing, in which case it will continue to fire.


shouldApply () {
    return 0
}

apply () {

[[ -f "${mission?}" ]]
[[ -f "${subtitles?}" ]]


tempfile=$(mktemp)
tempscript=$(mktemp)

echo "$tempscript"

echo "" > "$tempfile"
echo "" > "$tempscript"
$ed "$mission" >/dev/null <<EOF
g/graphics.artillery/?LinkTrId?\\
.W $tempfile\\
/XPos/ \\
.W $tempfile\\
/ZPos/ \\
.W $tempfile\\
/Country/ \\
.W $tempfile

q
EOF


dos2unix "$tempfile"

readarray -t arty_ids <<< $(sed -n -e '/LinkTrId/s/.*= *\([[:digit:]]*\);.*/\1/p' "$tempfile" )
readarray -t xpos_a <<< $(sed -n -re '/XPos/s/.*= *(.*);.*/\1/p' "$tempfile" )
readarray -t zpos_a <<< $(sed -n -re '/ZPos/s/.*= *(.*);.*/\1/p' "$tempfile" )
readarray -t countries <<< $(sed -n -e '/Country/s/.*= *\([[:digit:]]*\);.*/\1/p' "$tempfile" )

N="${#arty_ids[@]}"
if (( "$N" != "${#xpos_a[@]}" )) ; then echo "xpos mismatch" ; exit 1 ; fi
if (( "$N" != "${#zpos_a[@]}" )) ; then echo "zpos mismatch" ; exit 1 ; fi
if (( "$N" != "${#countries[@]}" )) ; then echo "countries mismatch" ; exit 1 ; fi

echo "artillery count: $N"


index=$(sed -n -re '/Index\s*=/s/Index\s*=\s*([0-9]*);/\1/p' "${mission}" | tr -d ' \r' | sort -nr | head -n 1)
printf "max index: %q\n" "$index"

for i in $(seq 0 $((N - 1)) )
do

eid="${arty_ids[$i]}"
XPos="${xpos_a[$i]}"
ZPos="${zpos_a[$i]}"
Country="${countries[$i]}"

# echo "eid: $eid"
# echo "XPOS: $XPos"
# echo "ZPOS: $ZPos"
# echo "Country: $Country"

echo "/LinkTrId *= *$eid;/
/Vulnerable/s/.*/  Vulnerable = 0;/
/}/
+1a
Block
{
  Name = \"Hard\";
  Index = $((index + 1));
  LinkTrId = $((index + 2));
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Model = \"graphics\blocks\fake_block.mgm\";
  Script = \"LuaScripts\WorldObjects\Blocks\fake_block.txt\";
  Country = $Country;
  Desc = \"\";
  Durability = 7500;
  DamageReport = 50;
  DamageThreshold = 1;
  DeleteAfterDeath = 1;
}

MCU_TR_Entity
{
  Index = $((index + 2));
  Name = \"Block entity\";
  Desc = \"\";
  Targets = [];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Enabled = 1;
  MisObjID = $((index + 1));
  OnEvents
  {
    OnEvent
    {
      Type = 13;
      TarId = $((index + 9));
    }
  }
}

Block
{
  Name = \"Soft\";
  Index = $((index + 3));
  LinkTrId = $((index + 4));
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Model = \"graphics\blocks\fake_block.mgm\";
  Script = \"LuaScripts\WorldObjects\Blocks\fake_block.txt\";
  Country = $Country;
  Desc = \"\";
  Durability = 0;
  DamageReport = 50;
  DamageThreshold = 1;
  DeleteAfterDeath = 1;
}

MCU_TR_Entity
{
  Index = $((index + 4));
  Name = \"Block entity\";
  Desc = \"\";
  Targets = [];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Enabled = 1;
  MisObjID = $((index + 3));
  OnEvents
  {
    OnEvent
    {
      Type = 13;
      TarId = $((index + 8));
    }
  }
}

MCU_CMD_Damage
{
  Index = $((index + 5));
  Name = \"Kill\";
  Desc = \"\";
  Targets = [];
  Objects = [$eid];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Damage = 2;
  Type = 1;
}

MCU_CMD_Damage
{
  Index = $((index + 6));
  Name = \"Flee\";
  Desc = \"\";
  Targets = [];
  Objects = [$eid];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Damage = 0;
  Type = 1;
}

MCU_CMD_Behaviour
{
  Index = $((index + 7));
  Name = \"MakeVulnerable\";
  Desc = \"\";
  Targets = [];
  Objects = [$eid];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Filter = 1;
  Vulnerable = 1;
  Engageable = 1;
  LimitAmmo = 1;
  RepairFriendlies = 0;
  RehealFriendlies = 1;
  RearmFriendlies = 0;
  RefuelFriendlies = 0;
  AILevel = 2;
  Country = 0;
  FloatParam = 0;
}

MCU_Timer
{
  Index = $((index + 8));
  Name = \"0\";
  Desc = \"\";
  Targets = [$((index + 15)),$((index + 14))];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0;
  Random = 100;
}

MCU_Timer
{
  Index = $((index + 9));
  Name = \"0\";
  Desc = \"\";
  Targets = [$((index + 12)),$((index + 7))];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0;
  Random = 100;
}

MCU_Timer
{
  Index = $((index + 10));
  Name = \"20ms\";
  Desc = \"\";
  Targets = [$((index + 13))];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0.02;
  Random = 100;
}

MCU_Timer
{
  Index = $((index + 11));
  Name = \"20ms\";
  Desc = \"\";
  Targets = [$((index + 10)),$((index + 6))];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0.02;
  Random = 100;
}

MCU_Timer
{
  Index = $((index + 12));
  Name = \"20ms\";
  Desc = \"\";
  Targets = [$((index + 5))];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0.02;
  Random = 100;
}

MCU_CMD_Behaviour
{
  Index = $((index + 13));
  Name = \"MakeInVulnerable\";
  Desc = \"\";
  Targets = [];
  Objects = [$eid];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Filter = 1;
  Vulnerable = 0;
  Engageable = 1;
  LimitAmmo = 1;
  RepairFriendlies = 0;
  RehealFriendlies = 1;
  RearmFriendlies = 0;
  RefuelFriendlies = 0;
  AILevel = 2;
  Country = 0;
  FloatParam = 0;
}

MCU_CMD_ForceComplete
{
  Index = $((index + 14));
  Name = \"command Force Complete\";
  Desc = \"\";
  Targets = [];
  Objects = [$eid];
  XPos = $XPos;
  YPos = 107.383;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Priority = 2;
  EmergencyOrdnanceDrop = 0;
}

MCU_Timer
{
  Index = $((index + 15));
  Name = \"120ms\";
  Desc = \"\";
  Targets = [$((index + 7)),$((index + 11))];
  Objects = [];
  XPos = $XPos;
  YPos = 0;
  ZPos = $ZPos;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0.20;
  Random = 100;
}

." >> "$tempscript"

((index += 15)) # number of items added.

done

echo "w
q" >> "$tempscript"

{ cat "$tempscript" | $ed "$mission"  > /dev/null ; }

echo "$tempscript"
}