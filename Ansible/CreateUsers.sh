#!/bin/bash

####################################################################################################
#
# Copyright (c) 2022, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#   Author: Josh Harvey
#   Last Modified: 07/28/2022
#   Version: 0.1
#
#   Description: This script will create user accounts based on the users entered in script parameter
#   number 4 (seperated by commas)
#
####################################################################################################

################# VARIABLES ######################
## userAccounts: The list of users you want to create, seperated by commas **REQUIRED**
userAccounts="$4"
## currentUser: Grabs the username of the current logged in user **DO NOT CHANGE**
currentUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')
## createUsersLog: Location of the CreateUsers script log **DO NOT CHANGE**
createUsersLog="/private/var/log/CreateUsers.log"
## currentTime: Gets the time for the log **DO NOT CHANGE**
currentTime=$(date +%H:%M)

## Logging Function
log_it () {
    if [[ ! -z "$1" && -z "$2" ]]; then
        logEvent="INFO"
        logMessage="$1"
    elif [[ "$1" == "warning" ]]; then
        logEvent="WARN"
        logMessage="$2"
    elif [[ "$1" == "success" ]]; then
        logEvent="SUCCESS"
        logMessage="$2"
    elif [[ "$1" == "error" ]]; then
        logEvent="ERROR"
        logMessage="$2"
    fi

    if [[ ! -z "$logEvent" ]]; then
        echo ">>[CreateUsers.sh] :: $logEvent [$(date +%H:%M)] :: $logMessage"
        echo ">>[CreateUsers.sh] :: $logEvent [$(date +%H:%M)] :: $logMessage" >> "$createUsersLog"
    fi
}

macOSArch=$(/usr/bin/uname -m)

create_users () {
    for u in ${userList//,/ }; do
        uidGen=$(awk 'BEGIN{srand();print int(rand()*(1500-1200))+505 }')
        dscl . -create /Users/"$u"
        dscl . -create /Users/"$u" UserShell /bin/bash
        dscl . -create /Users/"$u" UniqueID $uidGen
        dscl . -create /Users/"$u" PrimaryGroupID 80
        dscl . -create /Users/"$u" NFSHomeDirectory /Users/"$u"
        dscl . -append /Groups/admin GroupMembership "$u"
        cp -R /System/Library/User\ Template/English.lproj /Users/"$u"
        log_it "info" "Created $u user account"
        echo "$u ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$u"
        log_it "info" "Created sudoers.d file for $u"
        /bin/cat > /Users/"$u"/.bash_profile <<'bash_profile'
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
bash_profile
        log_it "info" "Created bash_profile for user $u"

        if [[ "$macOSArch" == "x86_64" ]]; then
            log_it "System Architecture: Intel (64-Bit)"
            /bin/cat > /Users/"$u"/.bashrc << 'bashrc'
export NVM_DIR="$/usr/local/bin/.nvm"

# support for UTF-8 encoding
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home"
export PATH=/usr/local/bin:$PATH
# brew installs python3 by default
alias python=/usr/local/bin/python3
alias pip=/usr/local/bin/pip3
bashrc
        elif [[ "$macOSArch" == "arm64" ]]; then
            log_it "System Architecture: Apple Silicon 64-Bit"
            /bin/cat > /Users/"$u"/.bashrc << 'bashrcApple'
export NVM_DIR="$/usr/local/bin/.nvm"

# support for UTF-8 encoding
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home"
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
# brew installs python3 by default
alias python=/opt/homebrew/bin/python3
alias pip=/opt/homebrew/bin/pip3
bashrcApple
        fi
        log_it "info" "Created .bashrc for $u"

    done
}


if [[ ! -z "$4" ]]; then
    userList="$4"
    create_users
else
    log_it "error" "Missing list of users to create (Script Parameter #4)"
    exit 1
fi