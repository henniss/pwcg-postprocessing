# By default, we try to intelligently select the map for this mission, but it's possible to override it on a per-campaign basis, if this gives you any trouble.
MAP=$(grep "GuiMap" "$mission" -m 1 | tr -d '\r' | sed 's/.*"\([[:alpha:]]*\).*";/\1/')

# Thse parameters let you customize if and how flight start times are smeared out in time. 'B' determines the size, in seconds, of each bucket. 'N' determines the number of buckets. And 'A' is an offset, also in seconds. See components/05_timers.sh for details.
export TIMERS_B="$((15 * 60))"
export TIMERS_A=0
export TIMERS_N=1

# These should be set in the env.sh file for each campaign. tac_code_pattern is as described in printf(3); it will be passed a single string.
# export tac_code_pattern='7Y%1$s%1$s'
# export tac_code_color="1111"

# Use a larger VWP radius.
export VWP_RADIUS_OVERRIDE=23000