
: "${RADIUS:=3000}"

shouldApply () {

[[ -f "${mission?}" ]] || return 1
[[ -f "${subtitles?}" ]] || return 1

[[ "$IS_MISSION_WITH_ESCORT" == true ]] || { echo "not an escort mission" ; return 1 ; }
}

apply() {
set -e

tempfile=$(mktemp)
ring=$(mktemp)

$ed "$mission"  <<EOF
/Name = "Flight/
ka
/Plane/
/LinkTrId/
.w $tempfile
/XPos/
.W $tempfile
/ZPos/
.W $tempfile
'a
/Rendezvous
/XPos
.W $tempfile
/YPos
.W $tempfile
/ZPos
.W $tempfile
?MCU_Waypoint
/Index
.W $tempfile
'a
/Name = "TakeOff";
?MCU_Waypoint
/Index
.W $tempfile
EOF


# Crude, but do this separatly to avoid escape characters.
grep -F "Flight $ESCORT_FLIGHT" "${mission}" -n
ESCORT_START=$(grep -F "Flight $ESCORT_FLIGHT" "${mission}" -n  | tr -d '\r' | head -n 1 | cut -d : -f 1)
echo "escorts start at: $ESCORT_START"

$ed "$mission" >/dev/null <<EOF
$ESCORT_START
ka
/Name = "Escort Cover Force Complete Tim.*"/
?Index =?
.W $tempfile
'a
/Plane/
/LinkTrId/
.W $tempfile
'a
/Name = "Rendezvous";/
?MCU_Waypoint?
kb
/Index/
.W $tempfile
/YPos/
.W $tempfile
EOF


sed -i -re 's/\r//' "$tempfile"
sed -i -re 's/.*=\s*([0-9.]*);/\1/' "$tempfile"
readarray -t tempdata < "$tempfile"

# ID of the lead plane, player flight.
PID="${tempdata[0]}"
# player's position
FXPOS="${tempdata[1]}"
FZPOS="${tempdata[2]}"
# rendezvous position
XPOS="${tempdata[3]}"
YPOS="${tempdata[4]}"
ZPOS="${tempdata[5]}"
# rendezvous id (player side)
RDV="${tempdata[6]}"
# take-off waypoint id
TOWID="${tempdata[7]}"
# id for the escort-timer-force-complete timer -- doesn't seem to work?
ECFCT_ID="${tempdata[8]}"
# escort leader's id
ESCORT_ID="${tempdata[9]}"
# escort flight's rendezvous id
ERDV_ID="${tempdata[10]}"
# escort flight's rendezvous altitude
E_YPOS="${tempdata[11]}"

for var in PID FXPOS FZPOS XPOS YPOS ZPOS RDV TOWID ECFCT_ID ESCORT_ID ERDV_ID; do
  echo "${var}: ${!var@Q}"
done

six_roots_x=(1 0.5 -0.5 -1 -0.5 0.5)
six_roots_z=(0 0.86 0.86 0 -0.86 -0.86)

index=$(sed -n -re '/Index\s*=/s/Index\s*=\s*([0-9]*);/\1/p' "${mission}" | tr -d ' \r' | sort -nr | head -n 1)
printf "max index: %q\n" "$index"

ring_start=$((index + 1))

cat >>"$ring" <<EOF
?end of file?
-1i

EOF

for i in $(seq 0 5); do

Xi=$(echo "$XPOS + 1000 * ${six_roots_x[$i]}" | bc)
Zi=$(echo "$ZPOS + 1000 * ${six_roots_z[$i]}" | bc)
   
cat >>$ring <<EOF
MCU_Waypoint
  {
    Index = $(($index + 1 + $i));
    Name = "Ring_${i}";
    Desc = "";
    Targets = [$(($index + 1 + ((1 + $i ) % 6)))];
    Objects = [${ESCORT_ID}];
    XPos = $Xi;
    YPos = $E_YPOS;
    ZPos = $Zi;
    XOri = 0.00;
    YOri = 270.80;
    ZOri = 0.00;
    Area = 500;
    Speed = 300;
    Priority = 1;
  }
  
EOF

done
cat >>$ring <<EOF
.
w
q
EOF

echo "Inserting ring."
$ed "$mission" <"$ring"

(( index+=6 ))

escort_to_ring="\
/Index.*=.*${ERDV_ID};/
/Targets/
s/Targets.*/  Targets = [${ring_start}];
w
q
"

echo "Attaching ring."
echo "${escort_to_ring?}" | $ed "$mission" 


escort_acquire="\$
?end of file?
-1i

MCU_CheckZone
{
  Index = $((index + 1));
  Name = \"Rendezvous CZ\";
  Desc = \"\";
  Targets = [$((index + 4)),$((index + 5)),$((index + 6)),$((index + 7)),$((index + 9))];
  Objects = [$PID];
  XPos = $XPOS;
  YPos = 46.317;
  ZPos = $ZPOS;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Zone = $RADIUS;
  Cylinder = 1;
  Closer = 1;
}

MCU_Deactivate
{
  Index = $((index + 4));
  Name = \"Once\";
  Desc = \"\";
  Targets = [$((index + 1))];
  Objects = [];
  XPos = 21305.685;
  YPos = 47.353;
  ZPos = 107271.046;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
}

MCU_Timer
{
  Index = $((index + 5));
  Name = \"2s\";
  Desc = \"\";
  Targets = [$RDV];
  Objects = [];
  XPos = 21312.805;
  YPos = 47.384;
  ZPos = 107250.681;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 2;
  Random = 100;
}

MCU_CMD_ForceComplete
{
  Index = $((index + 6));
  Name = \"Cancel Waypoints\";
  Desc = \"\";
  Targets = [];
  Objects = [$PID];
  XPos = 21303.958;
  YPos = 47.087;
  ZPos = 107251.342;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Priority = 2;
  EmergencyOrdnanceDrop = 0;
}

MCU_TR_Subtitle
{
  Index = $((index + 7));
  Name = \"DEBUG\";
  Desc = \"\";
  Targets = [];
  Objects = [];
  XPos = 21305.353;
  YPos = 47.277;
  ZPos = 107271.350;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Enabled = 1;
  SubtitleInfo
  {
    Duration = 5;
    FontSize = 30;
    HAlign = 1;
    VAlign = 2;
    RColor = 255;
    GColor = 0;
    BColor = 0;
    LCText = 9999;
  }
  
  Coalitions = [0, 1, 2, 3, 4];
}

MCU_Timer
{
  Index = $((index + 16));
  Name = \"Takeoff ReportTarget\";
  Desc = \"\";
  Targets = [$((index + 17)), $TOWID];
  Objects = [];
  XPos = 21312.805;
  YPos = 47.384;
  ZPos = 107250.681;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0;
  Random = 100;
}

MCU_Timer
{
  Index = $((index + 17));
  Name = \"30s\";
  Desc = \"\";
  Targets = [$((index + 1))];
  Objects = [];
  XPos = 21312.805;
  YPos = 47.384;
  ZPos = 107250.681;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 30;
  Random = 100;
}
.
1
/Index.*=.*$PID;/
/OnMsg/
/TarId/s/[[:digit:]]*;/$((index + 16));/
w
q
"

escort_home="\$
?end of file?
-1i
MCU_CheckZone
{
  Index = $((index + 8));
  Name = \"Origin CZ\";
  Desc = \"\";
  Targets = [$((index + 11)),$((index + 14)),$((index + 15))];
  Objects = [$PID];
  XPos = $FXPOS;
  YPos = 46.317;
  ZPos = $FZPOS;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Zone = 2500;
  Cylinder = 1;
  Closer = 1;
}

MCU_Timer
{
  Index = $((index + 9));
  Name = \"10m\";
  Desc = \"\";
  Targets = [$((index + 8)),$((index + 10)),$((index + 13))];
  Objects = [];
  XPos = 21629.601;
  YPos = 230.517;
  ZPos = 106296.270;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 600;
  Random = 100;
}

MCU_CheckZone
{
  Index = $((index + 10));
  Name = \"RDV CZ\";
  Desc = \"\";
  Targets = [$((index + 11)),$((index + 15)),$((index + 14))];
  Objects = [$PID];
  XPos = $XPOS;
  YPos = 46.317;
  ZPos = $ZPOS;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Zone = 2500;
  Cylinder = 1;
  Closer = 1;
}

MCU_Timer
{
  Index = $((index + 11));
  Name = \"0s\";
  Desc = \"\";
  Targets = [$ECFCT_ID,$((index + 12))];
  Objects = [];
  XPos = 22354.265;
  YPos = 171.132;
  ZPos = 105944.913;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0;
  Random = 100;
}

MCU_TR_Subtitle
{
  Index = $((index + 12));
  Name = \"DEBUG\";
  Desc = \"\";
  Targets = [];
  Objects = [];
  XPos = 22355.455;
  YPos = 171.136;
  ZPos = 105944.924;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Enabled = 1;
  SubtitleInfo
  {
    Duration = 5;
    FontSize = 30;
    HAlign = 1;
    VAlign = 2;
    RColor = 255;
    GColor = 0;
    BColor = 0;
    LCText = 9998;
  }
  
  Coalitions = [0, 1, 2, 3, 4];
}

MCU_TR_Subtitle
{
  Index = $((index + 13));
  Name = \"DEBUG\";
  Desc = \"\";
  Targets = [];
  Objects = [];
  XPos = 21630.575;
  YPos = 176.565;
  ZPos = 106297.398;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Enabled = 1;
  SubtitleInfo
  {
    Duration = 5;
    FontSize = 30;
    HAlign = 1;
    VAlign = 2;
    RColor = 255;
    GColor = 0;
    BColor = 0;
    LCText = 9997;
  }
  
  Coalitions = [0, 1, 2, 3, 4];
}

MCU_Deactivate
{
  Index = $((index + 14));
  Name = \"CZ fire once\";
  Desc = \"\";
  Targets = [$((index + 8))];
  Objects = [];
  XPos = 21646.066;
  YPos = 176.988;
  ZPos = 106290.628;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
}


MCU_Deactivate
{
  Index = $((index + 15));
  Name = \"CZ fire once\";
  Desc = \"\";
  Targets = [$((index + 10))];
  Objects = [];
  XPos = 21696.938;
  YPos = 176.988;
  ZPos = 108125.518;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
}
.
w
q
"

((index += 17))

echo "${escort_acquire?}" | $ed "$mission" 
if ! [[ "$IS_ESCORT" == true ]] ; then
    echo "${escort_home?}" | $ed "$mission" >/dev/null
fi

echo -n -e "9997:\r\n9998:Escort RTB\r\n9999:Rendezvous Met\r\n" | iconv -f ASCII -t "UTF-16LE" >> "$subtitles"

echo "update rendezvous"
printf "%q\n" "${RDV}"
# Update rendezvous radius too.
$ed "$mission" > /dev/null <<EOF
/Index.*=.*$RDV;/
?MCU_Waypoint?
ka
/}/
kb
'a,'bg/Area/
s/Area =.*;/Area = $RADIUS;/
w
q
EOF
}
