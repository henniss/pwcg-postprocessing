This repo contains scripts to tweak PWCG missions to my tastes. 

They're all kind of crap; I threw these together quickly to solve problems as I ran into them, but they're not polished or anything. 

Installation: 

* Install cygwin. Make sure to select the ed, jq, libiconv, and perl packages. 
* Edit core.sh and make sure to point the relevant variables to appropriate filesystem paths.
* Set "Build Binary Mission File" to 0 in PWCG global configs.
* Generate a new mission.
* Drag and drop the generated .mission file onto core.bat
* default_env.sh also contains some parameters that you can tune. A file named env.sh in the campaign directory can be used to override these on a per-campaign basis. 
* You can also put a file pilot-code-map.csv in the campaign directory to determine how pilots get mapped to tac codes; the columns are "Pilot Name", "Unused", and "Code"

Individual tweaks are packaged in the components/ folder, you can delete whichever tweaks you don't want. Numerical prefixes determine the order they are applied.
