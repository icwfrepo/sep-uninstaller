#!/usr/bin/env sh

# GitHub: @captam3rica

#
#   NAME
#
#      Uninstall Symantec Endpoint Protection
#
#   TESTED AGAINST VERSIONS
#
#       - SEP 14.2.0
#
#   DESCRIPTION
#
#       The below contains path information pertaining to directories and files
#       belonging to SEP. It is possible that some of theses paths maybe
#       changed, removed, updated, depending on the version of SEP installed.
#
#       When a new version is released it is recommend to reconfirm this
#       information.
#
#       Leverage the following command to find files in the OS related to SEP.
#
#           sudo find / -iname "*symantec*"
#
#           / - look starting in the root directory
#           -iname - ignore case
#

VERSION=0.2.1


# Current user
CURRENT_USER=$(/usr/bin/stat -f '%Su' /dev/console)

# Script name
SCRIPT_NAME=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')

###############################################################################
# Base directories
###############################################################################
ROOT_LIB="/Library"
USER_LIB="/Users/$CURRENT_USER/Library"
LAUNCH_DAEMONS="$ROOT_LIB/LaunchDaemons"
LAUNCH_AGENTS="$ROOT_LIB/LaunchAgents"
LOG_DIR="$ROOT_LIB/Logs"
SERVICES="$ROOT_LIB/Services"
APP_SUPPORT="$ROOT_LIB/Application Support"

###############################################################################
# LauchDeamons and LaunchAgents
###############################################################################
SYM_LAUNCH_DAEMONS_PLIST="$LAUNCH_DAEMONS/com.symantec.*"
SYM_LAUNCH_AGENTS_PLIST="$LAUNCH_AGENTS/com.symantec.*"
DAEMON_LIST="
com.symantec.SymLUHelper.NFM
com.symantec.UninstallerToolHelper
com.symantec.sharedsettings.NFM
com.symantec.symqual.crashreporter.NFM
com.symantec.symqual.panicreporter.NFM
com.symantec.symqual.submit.NFM
com.symantec.symsharedsettings2.NFM
com.symantec.liveupdate.daemon.NFM
com.symantec.sep.Migration.NFM.plist"

###############################################################################
# UI Agent
###############################################################################
UI_AGENT="/private/var/folders/kl/040bdqhs441dd1dt_99fzppw0000gp/C/com.symantec.uiagent.application"

###############################################################################
# Symantec preference information
###############################################################################
SEP_PREFS="$ROOT_LIB/Preferences/com.symantec.*"
SEP_APP_SUPPORT="$APP_SUPPORT/Symantec"
SEP_APP_SUPPORT_2="$APP_SUPPORT/regid.1992-12.com.symantec_Endpoint_Protection.swidtag"
SEP_APP_SUPPORT_3="$APP_SUPPORT/regid.1992-12.com.symantec_Endpoint_Protection_Mac_Client.swidtag"

###############################################################################
# Caches
###############################################################################
SYM_CACHE_USER="$USER_LIB/Caches/com.symantec.sep.mainapp"

###############################################################################
# Receipts
###############################################################################
SYM_RECEIPTS="/var/db/receipts/com.symantec.*"

###############################################################################
# Temp files
###############################################################################
SYM_TEMP_FILES="/var/tmp/com.symantec.*"

###############################################################################
# Logs
###############################################################################
SYMANTEC_LOG="$LOG_DIR/Symantec"
ERRROR_LOG="$LOG_DIR/SymantecErrorReporting.NFM.log"

###############################################################################
# KEXT
###############################################################################
KEXT_LIST="
/Library/Extensions/SymIPS.kext
/Library/Extensions/SymInternetSecurity.kext
/Library/Extensions/SymXIPS.kext"

###############################################################################
# etc ...
###############################################################################
ETC_SYMANTEC="/private/etc/symantec"
SYMANTEC_SERVICE="$SERVICES/Symantec Service.service"
SY_LINK_DROP_HELPER="/usr/local/bin/com.symantec.sep.SyLinkDropHelper"
CACHES_DAEMON="/private/var/root/Library/Caches/com.symantec.daemon"
SYM_DAEMON_LAUNCHES="/private/tmp/com.symantec.symdaemon.launches"
SYMANTEC_KEYCHAIN="/private/var/db/com.symantec/Symantec.keychain"
SYMANTEC_KEYCHAIN_DIR="/private/var/db/com.symantec"
APPLICATION="/Applications/Symantec Solutions"

###############################################################################


run_as_root() {
 # Pass in the full path to the executable as $1
 # Pass in the name of the script as $2

 if [ "$(/usr/bin/id -u)" -ne 0 ] ; then
     # If not running the script as root user.
     /bin/echo
     /bin/echo "This application must be run as root."
     /bin/echo "Please authenticate below."
     /bin/echo
     sudo "${1}/${2}" && exit 0
 fi
}


delete() {
 # Function to delete stuff
 /bin/rm -Rf "$1"
}


logging() {
    # Pe-pend text and print to standard output
    # Takes in a log level and log string.
    # Example: logging "INFO" "Something describing what happened."

    log_level=$(printf "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    LOG_FILE="$SCRIPT_NAME""_log-$(date +"%Y-%m-%d").log"
    LOG_PATH="$ROOT_LIB/Logs/$LOG_FILE"

    if [ -z "$log_level" ]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [ -z "$log_statement" ]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    DATE=$(date +"[%b %d, %Y %Z %T $log_level]:")
    printf "%s %s\n" "$DATE" "$log_statement" >> "$LOG_PATH"
}

remove_sep_daemons() {
 # Remove the Deamon information from LaunchDaemons and LaunchAgents

    # Unload the daemons
    logging "" ""
    logging "" "Checking to see if any SEP daemons are loaded ..."
    logging "" ""

    for daemon in $DAEMON_LIST; do

        ld_name=$(/usr/bin/basename "$daemon")

        symantec=$(/bin/launchctl list | \
            /usr/bin/grep "$daemon" | \
            /usr/bin/awk '{print $3}' | \
            /usr/bin/awk -F '.' '{print $2}')

        # logging DEBUG "Output from symantec variable: $symantec"

        if [ "$symantec" = "symantec" ]; then
            # Found that a SEP daemon is running so we need to unload it.

            logging "" "The $ld_name daemon is loaded."
            logging "" "Stopping ..."
            /bin/launchctl stop "$daemon"
            logging "" "Unloading ..."
            /bin/launchctl unload "/Library/LaunchDaemons/$daemon.plist"
            /bin/sleep 1

        else
            # Nothing loaded
            logging "" "Nothing loaded ..."
        fi

    done

    logging "" ""
    logging "" "Looking for LaunchDaemons and LaunchAgents associated with SEP ..."
    logging "" ""

    for plistd in $SYM_LAUNCH_DAEMONS_PLIST \
        $SYM_LAUNCH_AGENTS_PLIST \
        $UI_AGENT \
        $SYM_CACHE_USER; do

        plistd_name=$(/usr/bin/basename "$plistd")

        if [ -f $plistd ]; then
            # Print that we found the daemon

            logging "" "Removing $plistd_name daemon plist ..."
            delete $plistd
            /bin/sleep 1

        elif [ -e $plistd ]; then
            # Print that we found the daemon

            logging "" "Removing $plistd_name daemon plist ..."
            delete "$plistd"
            /bin/sleep 1

        else
            # Daemon either does not exist or was moved.
            logging "" "Did not find: $plistd plist"
            logging "" "Either it does not exist, it was renamed, or moved ..."

        fi

        done

        # Kill daemon processes
        logging "" ""
        logging "" "Checking to see if any SEP processes are running ..."

        for proc in SymDaemon Symantec SymSharedSettingsd; do

            pid=$(/usr/bin/pgrep $proc 2> /dev/null)

            if [ $? -eq 0 ]; then
                # Kill the daemon

                logging "" "$proc process is running ..."
                logging "" "Killing $proc($pid) ..."
                /usr/bin/killall "$proc"
                /bin/sleep 1

            else
                # Process is not Running
                logging "" "$proc process is not running ..."
                fi

            done

}


remove_sep_preferences() {
    # Symantec preference information

    logging "" ""
    logging "" "Looking for SEP preference files ..."

    for pref in $SEP_PREFS "$SEP_APP_SUPPORT" "$SEP_APP_SUPPORT_2" \
    "$SEP_APP_SUPPORT_3"; do

        pref_file_name=$(/usr/bin/basename "$pref")

        if [ -f "$pref" ]; then
            # Remove the file

            logging "" "Removing $pref_file_name preference ..."
            delete "$pref"
            /bin/sleep 1

            elif [ -d "$pref" ]; then
            # Found directory

            logging "" "Deleting Directory $pref_file_name"
            delete "$pref"
            /bin/sleep 1

            elif [ -e "$pref" ]; then
            # Remove the file

            logging "" "Removing $pref_file_name preference ..."
            delete $pref
            /bin/sleep 1

        else
            # Didn't find anything
            logging "" "Did not find anything related to $pref_file_name ..."
            logging "" "It either does not exist or was removed already ..."
        fi

    done

}


remove_sep_logs() {
    # Remove log files associated with SEP

    logging "" ""
    logging "" "Looking for SEP log files information ..."

    for log in $SYMANTEC_LOG $ERRROR_LOG; do

        log_name=$(/usr/bin/basename "$log")

        if [ -f $log ]; then
            # Found the log file

            logging "" "Removing $log_name ..."
            delete "$log"
            /bin/sleep 1

            elif [ -d $log ]; then
            # Found directory

            logging "" "Deleting $log_name directory ..."
            delete "$log"
            /bin/sleep 1

        else

            logging "" "$log_name does not exist ..."
            logging "" "It either does not exist or was removed already ..."

        fi

    done

}


remove_sep_receipts() {
    # Find and remove SEP receipt information

    logging "" ""
    logging "" "Checking for SEP receipts ..."

    for receipt in $SYM_RECEIPTS; do

        receipt_name=$(/usr/bin/basename "$receipt")

        if [ -f "$receipt" ]; then
            # Remove the receipt file

            logging "" "Removing $receipt_name ..."
            delete "$receipt"
            /bin/sleep 1

            elif [ -e "$receipt" ]; then
            # Remove the receipt file

            logging "" "Removing $receipt_name ..."
            delete "$receipt"
            /bin/sleep 1

        else
            # Receipt file not found
            logging "" "$receipt_name file not found ..."
            logging "" "It either does not exist or was removed already ..."
        fi
    done

}


remove_sep_temp_files() {
    # Find and remove SEP temp file information
    #
    # A socket is a special file used for inter-process communication. These
    # enable communication between two processes. In addition to sending data,
    # processes can send file descriptors across a Unix domain socket
    # connection using the sendmsg() and recvmsg() system.
    #
    # Unlike named pipes which allow only unidirectional data flow, sockets
    # are fully duplex-capable.
    #
    # A socket is marked with an s as the first letter of the mode string, e.g.
    # srwxrwxrwx /tmp/.X11-unix/X0

    logging "" ""
    logging "" "Checking for SEP temp files ..."

    for temp_file in $SYM_TEMP_FILES; do

        temp_file_name=$(/usr/bin/basename "$temp_file")

        if [ -e ${temp_file} ]; then
            # Remove the receipt file

            logging "" "Removing $temp_file_name ..."
            delete "$temp_file"
            /bin/sleep 1

        else
            # Receipt file not found
            logging "" "$temp_file_name file not found ..."
            logging "" "It either does not exist or was removed already ..."
        fi
    done

}


remove_sep_kext() {
    # Remove KEXT file

    logging "" ""
    logging "" "Checking for KEXT SEP files ..."

    for kext in $KEXT_LIST; do

        kext_name=$(/usr/bin/basename "$kext")

        if [ -f "$kext" ]; then
            # Remove the receipt file

            logging "" "Removing $kext_name ..."
            delete "$kext"
            /bin/sleep 1

        elif [ -d "$kext" ]; then
            # Remove the receipt file

            logging "" "Removing $kext_name directory..."
            delete "$kext"
            /bin/sleep 1

        elif [ -e "$kext" ]; then
            # Remove the receipt file

            logging "" "Removing $kext_name ..."
            delete "$kext"
            /bin/sleep 1

        else
            # Receipt file not found
            logging "" "$kext_name file not found ..."
            logging "" "It either does not exist or was removed already ..."
        fi
    done

}


remove_misc_sep_files() {
    # Remove the misc files left over by SEP
    #
    # Applications
    # Keychain files
    # Other files

    logging "" ""
    logging "" "Checking for miscillaneous SEP files ..."

    for misc in \
    $ETC_SYMANTEC "$SYMANTEC_SERVICE" $SY_LINK_DROP_HELPER $CACHES_DAEMON \
    $SYM_DAEMON_LAUNCHES $SYMANTEC_KEYCHAIN $SYMANTEC_KEYCHAIN_DIR \
    "$APPLICATION"; do

        misc_name=$(/usr/bin/basename "$misc")

        if [ -f "$misc" ]; then
            # Remove the receipt file

            logging "" "Removing $misc_name ..."
            delete "$misc"
            /bin/sleep 1

            elif [ -d "$misc" ]; then
            # Remove the receipt file

            logging "" "Removing $misc_name directory..."
            delete "$misc"
            /bin/sleep 1

            elif [ -e "$misc" ]; then
            # Remove the receipt file

            logging "" "Removing $misc_name ..."
            delete "$misc"
            /bin/sleep 1

        else
            # Receipt file not found
            logging "" "$misc_name file not found ..."
            logging "" "It either does not exist or was removed already ..."
        fi
    done

}


main() {
    # Main function

    logging "INFO" "Running: $0 $VERSION"
    logging "INFO" ""
    logging "INFO" "--- Begin SEP Uninstall ---"
    logging "INFO" ""

    for func in \
    run_as_root \
    remove_sep_daemons \
    remove_sep_preferences \
    remove_sep_logs \
    remove_sep_receipts \
    remove_sep_temp_files \
    remove_sep_kext \
    remove_misc_sep_files; do

        logging "" ""
        logging "" "Running: $func"
        "$func"

        if [ "$?" -ne 0 ]; then
            # An error occured

            logging "ERROR" "An error occured running $func ..."
            exit "$?"

        fi

    done

    logging "" "Opening log file ...$LOG_DIR/Logs/$SCRIPT_NAME""log-$(date +"%Y-%m-%d").log"
    /usr/bin/open "$LOG_DIR/$LOG_FILE"

    logging "" ""
    logging "" "--- End SEP Uninstall ---"
    logging "" ""

}


# Call Main
main
