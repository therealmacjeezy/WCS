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
#   Description: This script will create a launchd item and place the GetMiniData.sh script locally 
#   on the system.
#
####################################################################################################

################# VARIABLES ######################
## currentUser: Grabs the username of the current logged in user **DO NOT CHANGE**
currentUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')
## createUsersLog: Location of the CreateMiniData script log **DO NOT CHANGE**
createMiniData="/private/var/log/CreateMiniData.log"
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
        echo ">>[CreateMiniData.sh] :: $logEvent [$(date +%H:%M)] :: $logMessage"
        echo ">>[CreateMiniData.sh] :: $logEvent [$(date +%H:%M)] :: $logMessage" >> "$createMiniData"
    fi
}

if [[ ! -z "$4" ]]; then
    looperInstance="$4"
else
    log_it "error" "Missing looper instance (Script Parameter #4)"
    exit 1
fi

/bin/cat > /Users/jenkinspan/temp/get_mini_data.sh << 'get_mini_data'
#!/bin/bash

cd /Users/jenkinspan/temp/

# Get Hostname
hostname=$(scutil --get ComputerName)

# Set Looper Instance
looper_instance=$looperInstance

# Get Serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Get Processor & cores
processor=$(system_profiler SPHardwareDataType | awk -F':' '/Processors/ {print $2}' |xargs )
cores=$(system_profiler SPHardwareDataType | awk -F':' '/Cores:/ {print $2}' | xargs )

# Get RAM
ram=$(system_profiler SPHardwareDataType | awk -F':' '/Memory:/ {print $2}')

# Get Disk capacity
disk=$(df -H | awk '/\/System\/Volumes\/Data$/ {printf("%s\n", $2)}')

# OS version
sw_ver=$(sw_vers -productVersion)

# Get Xcode versions
xcode=$(/usr/local/bin/xcversion installed | awk '{print $1}' | xargs)

# Get swiftlint versions
swiftlint=$(/usr/local/bin/brew list swiftlint --versions | sed 's/swiftlint //')

# Get Network connection speed
nw_speed=$(ifconfig en0 | grep media | sed 's/.* (\(.*\))/\1/' | awk '{ print $1}')

# Get DNS servers
dns=$(cat /etc/resolv.conf | grep ^nameserver | awk '{print $2}'| xargs)

# Get FileVault status
file_vault=$(fdesetup isactive)

# Get Mini model
model=$(sysctl hw.model | awk -F':' '{print $2}' | xargs)

# Get http proxy
httpproxy=$(networksetup -getwebproxy Ethernet | xargs)

# Get https proxy
httpsproxy=$(networksetup -getsecurewebproxy Ethernet | xargs)

# Get .pac proxy
pacproxy=$(networksetup -getautoproxyurl Ethernet | xargs)

# Get Update_time
update_time=$(date "+%D %T %Z")

echo "{
\"looper_instance\": \"$looper_instance\",
\"serial\": \"$serial\",
\"processor\": \"$processor x $cores\",
\"ram\": \"$ram\",
\"disk\": \"$disk\",
\"sw_ver\": \"$sw_ver\",
\"xcode\": \"$xcode\",
\"swiftlint\": \"$swiftlint\",
\"nw_speed\": \"$nw_speed\",
\"dns\": \"$dns\",
\"file_vault\": \"$file_vault\",
\"model\": \"$model\",
\"httpproxy\": \"$httpproxy\",
\"httpsproxy\": \"$httpsproxy\",
\"pacproxy\": \"$pacproxy\",
\"update_time\": \"$update_time\"
}" > data.json

curl -X POST \
  http://deployer.walmart.com:80/api/$hostname \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d "@data.json"
get_mini_data

chmod 0755 /Users/jenkinspan/temp/get_mini_data.sh
log_it "info" "Created get_mini_data.sh and set permissions to 0755"

/bin/cat > /Library/LaunchDaemons/com.looper.get_mini_data.plist << 'launchd_item'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.looper.get-mini-data</string>
	<key>Program</key>
	<string>/Users/jenkinspan/temp/get_mini_data.sh</string>
	<key>StartInterval</key>
	<integer>3600</integer>
	<key>UserName</key>
	<string>jenkinspan</string>
</dict>
</plist>
launchd_item

chmod 0644 /Library/LaunchDaemons/com.looper.get_mini_data.plist
log_it "info" "Created get_mini_data.plist and set permissions to 0644"

launchctl load /Library/LaunchDaemons/com.looper.get_mini_data.plist
log_it "info" "Loaded get_mini_data.plist"