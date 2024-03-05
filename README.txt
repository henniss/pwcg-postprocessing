Scripts to tweak PWCG missions.

Usage: 

* Make sure you've installed cygwin with the ed, jq. You'll also need libiconv (git for windows installs this)
* Make sure you've added the cygwin bin directory to your $PATH, and associate .sh with cygwin.
* Edit core.sh and make sure to point the relevant variables to appropriate filesystem paths.
* Set "Build Binary Mission File" to 0 in PWCG global configs.
* Generate a new mission.
* Drag and drop the generated .mission file onto core.sh

File associations:
In an admin cmd instance:
assoc .sh=UNIXShell.Script
ftype UNIXShell.Script="C:\cygwin64\bin\mintty.exe" "%1" %*