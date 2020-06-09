#!/usr/bin/env sh

# GitHub: @captam3rica


#
#   A post-install script to launch the sepuninstaller
#


RESULT=0

# Define the current working directory
HERE=$(/usr/bin/dirname "$0")
SCRIPT_NAME="sepuninstaller.sh"
SCRIPT_PATH="$HERE/$SCRIPT_NAME"

main() {
    /usr/bin/logger "Setting permissions on the $SCRIPT_NAME ..."
    /bin/chmod 755 "$SCRIPT_PATH"
    /usr/bin/logger "Launching the $SCRIPT_NAME ..."
    /bin/sh "$SCRIPT_PATH"
}

# Call main
main

exit "$RESULT"
