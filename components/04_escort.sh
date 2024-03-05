
RADIUS=6000

shouldApply () {
return 1

[[ -f "${mission?}" ]] || return 1
[[ -f "${subtitles?}" ]] || return 1

if ! { cat "${subtitles}" | iconv -f "UTF-16LE" -t UTF-8 | grep -q "Escorted" ; } ; then
    echo "Not an escort flight."
    return 1
fi
}

apply() {

tempfile="scratch/escort.txt"
echo "" > $tempfile

$ed "$mission" <<EOF
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
/ZPos
.W $tempfile
?MCU_Waypoint
/Index
.W $tempfile
EOF

PID=$(sed -n -re '1s/.*LinkTrId.*=\s*([0-9]*);/\1/p' "$tempfile")
FXPOS=$(sed -n -re '2s/.*XPos.*=\s*([0-9.]*);/\1/p' "$tempfile")
FZPOS=$(sed -n -re '3s/.*ZPos.*=\s*([0-9.]*);/\1/p' "$tempfile")
XPOS=$(sed -n -re '4s/.*XPos.*=\s*([0-9.]*);/\1/p' "$tempfile")
ZPOS=$(sed -n -re '5s/.*ZPos.*=\s*([0-9.]*);/\1/p' "$tempfile")
RDV=$(sed -n -re '6s/.*Index.*=\s*([0-9]*);/\1/p' "$tempfile")

echo "PID: $PID"
echo "FXPOS: $FXPOS"
echo "FZPOS: $FZPOS"
echo "XPOS: $XPOS"
echo "ZPOS: $ZPOS"
echo "RDV: $RDV"

# Crude, but do this separatly to avoid escape characters.
ESCORT_START=$(grep -F "Flight $ESCORT_FLIGHT" "${mission}" -n  | head -n 1 | cut -d : -f 1)
echo "escorts start at: $ESCORT_START"

$ed "$mission" <<EOF
$ESCORT_START
ka
/Name = "Escort Cover Force Complete Tim.*"/
?Index =?
.W $tempfile
EOF

ECFCT_ID=$(sed -n -re '7s/.*Index.*=\s*([0-9]*);/\1/p' "$tempfile")
echo "ECFCT_ID: $ECFCT_ID"

escort_acquire="\$
?end of file?
-1i

MCU_CheckZone
{
  Index = 9790001;
  Name = \"Object player\";
  Desc = \"\";
  Targets = [9790004,9790005,9790006,9790007,9790009];
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

MCU_TR_MissionBegin
{
  Index = 9790002;
  Name = \"\";
  Desc = \"\";
  Targets = [9790003];
  Objects = [];
  XPos = 21304.740;
  YPos = 47.148;
  ZPos = 107271.387;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Enabled = 1;
}

MCU_Timer
{
  Index = 9790003;
  Name = \"3s\";
  Desc = \"\";
  Targets = [9790001];
  Objects = [];
  XPos = 21306.042;
  YPos = 46.765;
  ZPos = 107271.101;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 3;
  Random = 100;
}

MCU_Deactivate
{
  Index = 9790004;
  Name = \"\";
  Desc = \"\";
  Targets = [9790001];
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
  Index = 9790005;
  Name = \"Target Rendezvous\";
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
  Index = 9790006;
  Name = \"Object Player\";
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
  Index = 9790007;
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
.
w
q
"

escort_home="\$
?end of file?
-1i
MCU_CheckZone
{
  Index = 9790008;
  Name = \"Object player\";
  Desc = \"\";
  Targets = [9790011,9790014,9790015];
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
  Index = 9790009;
  Name = \"10m\";
  Desc = \"\";
  Targets = [9790008,9790010,9790013];
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
  Index = 9790010;
  Name = \"Object player\";
  Desc = \"\";
  Targets = [9790011,9790015,9790014];
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
  Index = 9790011;
  Name = \"Escort Cover Complete\";
  Desc = \"\";
  Targets = [$ECFCT_ID,9790012];
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
  Index = 9790012;
  Name = \"Translator Subtitle\";
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
  Index = 9790013;
  Name = \"Translator Subtitle\";
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
  Index = 9790014;
  Name = \"Trigger Deactivate\";
  Desc = \"\";
  Targets = [9790008];
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
  Index = 9790015;
  Name = \"Trigger Deactivate\";
  Desc = \"\";
  Targets = [9790010];
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

echo "${escort_acquire?}" | $ed "$mission"
if ! [[ "$IS_ESCORT" == true ]] ; then
    echo "${escort_home?}" | $ed "$mission"
fi

echo -n -e "9997:\r\n9998:Escort RTB\r\n9999:Rendezvous Met\r\n" | iconv -f ASCII -t "UTF-16LE" >> "$subtitles"


# Update rendezvous radius too.
$ed "$mission" <<EOF
/Index.*=.*$RDV;/
?MCU_Waypoint?
ka
/}/
kb
'a,'bg/Area/
s/Area =.*;/Area = $RADIUS;/
'a,'bp
w
q
EOF
}