# `installXcode.sh`

A quicker way to install Xcode on macOS systems via Jamf Pro.

----
## Requirements
  - Xcode Package uploaded to Jamf Pro
    - *Requires a free Developer Account for [developer.apple.com](https://developer.apple.com)*
  - A policy in Jamf Pro to install XcodeCLI with a custom trigger
  - [swiftDialog](https://github.com/bartreardon/swiftDialog) installed.
    - **Note:** This script will download and install swiftDialog if it's not found.
  - [unxip](https://github.com/saagarjha/unxip)
    - This is used to expand `Xcode.xip` faster than the default method

> Note: Before uploading Xcode to Jamf Pro, you will need to add `.pkg` to the end of `Xcode.xip`. (Example: `Xcode.xip.pkg`)

----
## Setup
  1. Create a new policy to **cache** Xcode with a custom trigger *(This will allow you to cache Xcode ahead of time to help speed up the install process.)*
  1. Add script to Jamf Pro Server and customize the variables in the table listed below
  1. Enter the Version of Xcode you are deploying *(Example: 13.4)* in Script Parameter #4
  1. Enter the custom trigger for the **cache** Xcode Policy in Script Parameter #5

   **Variable Name** | **Line Number** | **Usage**
   ----------------- | --------------- | ---------
   `XCODE_XIP_PATH` | 12 | Location to UNXIP Xcode to
   `UNXIP` | 13 | Location of `unxip` install
   `UTILITYDIR` | 14 | Location of the directory you put resource files in.

> Be sure to set the trigger and scope correctly. This will vary based on how you want to deploy it. 
   
----
## Logging
This script creates a log file at `/private/var/log/InstallXcode.log`