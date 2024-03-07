MAP=$(grep "GuiMap" "$mission" -m 1 | tr -d '\r' | sed 's/.*"\([[:alpha:]]*\).*";/\1/')

TIMERS_B="$((15 * 60))"
TIMERS_A=0
TIMERS_N=1