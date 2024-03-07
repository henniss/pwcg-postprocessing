apply () {

[[ -f "${mission?}" ]]
[[ -f "${subtitles?}" ]]


# This arranges for $N intervals of $B seconds long each. 
# Each flight which is rescheduled will have a delay chosen randomly and uniformlyish from within these intervals, 
# and flights are guaranteed to be distributed roughly evenly across these intervals. 
# $A provides an offset; delays cannot be negative, so setting A=-$B effectively collapses the first interval to size 0. 

# Ex: A=-1800, B=1800, N=2.
# Three flights would be distributed among the intervals [0,0], [0,1800], [0,0], respectively.
#  Effectively, only one flight would be delayed.

# Ex: A=900, B=0, N=1
# A constant delay. All flights would be delayed exactly 900s.

# 1800 = 30 minutes.
B=${TIMERS_B?}
A=${TIMERS_A?}
N=${TIMERS_N?}

(( $N == 0 )) && { echo "N must be greater than 0"; return 1; }

tempfile="$(mktemp)"

exempt="$PLAYER_FLIGHT
$ESCORT_NAME"

grep "Name = \"Flight.*\";" "${mission}" | tr -d '\r' | sort > "$tempfile"
sed -i "s/ *Name = \"Flight \(.*\)\";/\1/" "$tempfile"
eligible="$(comm -3 "$tempfile" <(echo "$exempt" | sort))"

# delete any empty lines, and sort things.
eligible="$(echo "$eligible" | sed -E '/^[[:space:]]*$/d' | shuf)"

echo "eligible"
echo "$eligible"
echo ""

i=0
index=$(sed -n -re '/Index\s*=/s/Index\s*=\s*([0-9]*);/\1/p' "${mission}" | sort -nr | head -n 1 | tr -d '\r')
echo "max index: $index"

while read f ; do

echo "$i: Adjusting ${f?}"
# prevent div by zero
B=$((B > 0 ? B : 1))
if (( N > 0)); then 
NT=$(( i * B + ($RANDOM % B) + A ))
else
NT=$A
fi
# Always at least a 1s delay. This lets us collapse the first interval to nothing, if A is negative.
if (( NT < 1 )); then
NT=1
fi
# parser seems to require a decimal point and stuff.
NT=$(printf "%.1f" $NT)
echo "$NT"

# It's most convienient to find the line number this way, so we don't need to escape anything.
ln=$(grep -F -n -m 1 "Name = \"Flight $f\";" "${mission}" | cut -d ':' -f 1)

edscript="${ln?}
/Mission Begin Timer/
/Time *= /s/= .*;/= $NT;/
p
w
q
"

echo "$edscript" | $ed "$mission"

# Now the hard part... we need to:
# Find the CZ Activate timer for the first waypoint. Record its outputs, and then replace them with []
# Also record its id.
# Record the position of CZ.
# Insert the new logic, with CZ Activate Retry Timer pointing at CZ Activate Timer and DV overlapping CZ.
# update CZ Activate timer to point at DV, CZ Activate Exclusion Timer.
# update CZ Activate Exclusion Timer to point at the targets recorded from CZ Activate Timer.

edscript="${ln?}
/Name *= *\"VWP Group Virtual WP Check Zone\";/
/Name *= *\"CZ Activate Timer\";/
-1
.w ${tempfile}
/Targets *=/
.W ${tempfile}
s/Targets *= *\[.*\];/Targets = [$((index + 1)),$((index + 2))];/

${ln?}
/Name *= *\"VWP Group Virtual WP Check Zone\";/
/Name *= *\"CZ\";/
?Index?
.W ${tempfile}
/Objects/
n
.W ${tempfile}
/XPos/
.W ${tempfile}
/ZPos/
.W ${tempfile}
w
q
"

echo "${edscript}" | $ed "${mission}"

CZ_ACTIVATE_TARGET=$(sed -n -re '1s/.*Index\s*=\s*([0-9]*);/\1/p' "$tempfile" | tr -d '\r')
RECEIVED_ACTIVATION_TARGETS=$(sed -n -re '2s/.*Targets\s*=\s*\[([0-9,]*)\];/\1/p' "$tempfile" | tr -d '\r')
CZ_TARGET=$(sed -n -re '3s/.*Index\s*=\s*([0-9]*);/\1/p' "$tempfile" | tr -d '\r')
CZ_OBJECTS=$(sed -n -re '4s/.*Objects\s*=\s*\[([0-9,]*)\];/\1/p' "$tempfile" | tr -d '\r')
CZ_XPOS=$(sed -n -re '5s/.*XPos.*=\s*([0-9.]*);/\1/p' "$tempfile" | tr -d '\r')
CZ_ZPOS=$(sed -n -re '6s/.*ZPos.*=\s*([0-9.]*);/\1/p' "$tempfile" | tr -d '\r')

echo "CZ_ACTIVATE_TARGET: ${CZ_ACTIVATE_TARGET?}"
echo "RECEIVED_ACTIVATION_TARGETS: ${RECEIVED_ACTIVATION_TARGETS?}"
echo "CZ_TARGET: $CZ_TARGET"
echo "CZ_OBJECTS: $CZ_OBJECTS"
echo "XPOS: $CZ_XPOS"
echo "ZPOS: $CZ_ZPOS"

# Change: New activate object.
# Deactivate also needs to hit CZ, DZ.

CZ_EXTRA='
MCU_CheckZone
{
  Index = $((index + 1));
  Name = \"DZ\";
  Desc = \"\";
  Targets = [$((index + 4)),$((index + 3))];
  Objects = [${CZ_OBJECTS}];
  XPos = ${CZ_XPOS};
  YPos = 2166.000;
  ZPos = ${CZ_ZPOS};
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Zone = 10000;
  Cylinder = 1;
  Closer = 1;
}

MCU_Timer
{
  Index = $((index + 2));
  Name = \"CZ Activate Exclusion Timer\";
  Desc = \"\";
  Targets = [$((index + 5)),${RECEIVED_ACTIVATION_TARGETS}];
  Objects = [];
  XPos = 37333.840;
  YPos = 119.294;
  ZPos = 28875.117;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 0.5;
  Random = 100;
}

MCU_Timer
{
  Index = $((index + 3));
  Name = \"CZ Activate Retry Timer\";
  Desc = \"\";
  Targets = [${CZ_ACTIVATE_TARGET}, $((index + 6))];
  Objects = [];
  XPos = 38327.075;
  YPos = 148.600;
  ZPos = 30737.611;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
  Time = 30;
  Random = 100;
}

MCU_Deactivate
{
  Index = $((index + 4));
  Name = \"Stop Activation\";
  Desc = \"\";
  Targets = [$((index + 1)),$((index + 2)),${CZ_TARGET}];
  Objects = [];
  XPos = 37105.612;
  YPos = 139.753;
  ZPos = 30183.673;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
}

MCU_Deactivate
{
  Index = $((index + 5));
  Name = \"Confirm Activation\";
  Desc = \"\";
  Targets = [$((index + 1))];
  Objects = [];
  XPos = 37623.060;
  YPos = 129.043;
  ZPos = 30078.284;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
}

MCU_Activate
{
  Index = $((index + 6));
  Name = \"Reactivation\";
  Desc = \"\";
  Targets = [$((index + 1)),${CZ_TARGET}];
  Objects = [];
  XPos = 37105.612;
  YPos = 139.753;
  ZPos = 30183.673;
  XOri = 0.00;
  YOri = 0.00;
  ZOri = 0.00;
}
'

# Insert the modified items at the start of the group.
cze=$(eval "echo \"$CZ_EXTRA\"")
edscript="${ln?}
/Name *= *\\\"VWP Group Virtual WP Check Zone\\\";/
/Desc *= *\\\"Self Deactivating CZ\\\";/a
$cze
.
w
q
"

echo "$edscript" | $ed "${mission}"

((index += 6)) # number of items in CZ_EXTRA
(( i += 1 ))
if (( N > 0 )); then (( i %= N )); else ((i = 0));  fi

done <<< "$eligible"

return 0
}