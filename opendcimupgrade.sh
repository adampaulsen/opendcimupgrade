#!/bin/bash

#I know the upgrade process for openDCIM isn't super complicated, but I want to make it easier and less error prone.
if [ ! $# == 1 ]; then
  echo -e "Useage: $0 FILENAME(eg openDCIM-19.01.tar.gz)"
  exit
fi
#My install of openDCIM got installed under the root user, so yeah, there's this check. Comment out if you knew what you were doing when you instlaled openDCIM.
if [[ $(id -u) -ne 0 ]]
    then echo "Please run as root"
    exit 1
fi

#varibles defined here
#create a unique number
d=$(date "+%s")
#This is the directory just above the installed directory. For me, for example, it's /opt/openDCIM
installeddir=$(pwd)
#This is the file name of the latest version of openDCIM that you just downloaded from the openDCIM website
versionfile=$1
#gets the folder name of the new version of openDCIM
newversionfolder=$(echo "$versionfile" | awk -F'.tar' '{print $1}')
#gets the foldername of the new version of openDCIM
oldversionfolder=$(ls -l "$installeddir" | grep opendcim | awk -F'>' '{print $2}')
images=$oldversionfolder/images
pictures=$oldversionfolder/pictures
drawings=$oldversionfolder/drawings

#functons defined here
config-data () {
        arg1=$1
        grep $arg1 $oldversionfolder/db.inc.php | awk -F':' '{print $2}' | sed $'s/[^[:alnum:]\t]//g'
}

copywperm () {
    perm=$(stat -c "%U:%G" "$1")
    sudo cp -R "$1" "$2/"
    sudo chown "$perm" "$2"
}

#Secondary variables
#Should be self-explanatory, but this is your openDCIM database username
dbusername=$(config-data OPENDCIM_DB_USER)
#Should be self-explanatory, but this is your openDCIM database password
dbpassword=$(config-data OPENDCIM_DB_PASS)
#Should be self-explanatory, but this is your openDCIM database name
dcimdb=$(config-data OPENDCIM_DB_NAME)

#Things happen here
#Extract the archive
echo "Extrating $versionfile"
sudo tar -zxf "$versionfile"
#backup DCIM database
echo "Creating DB backup"
sudo mysqldump --user="$dbusername" --password="$dbpassword" --opt "$dcimdb" | sudo tee -a "$installeddir"/backups/dcimbackup-"$d".sql
#rename the new config file
echo "Creating new config..."
sudo cp "$newversionfolder"/db.inc.php-dis "$newversionfolder"/db.inc.php
#copy the .htaccess file from old to new
echo "Copying .htaccess file from $oldversionfolder to $newversionfolder"
sudo cp "$oldversionfolder"/.htaccess "$newversionfolder"/.htaccess
#copy the images folder from the old location to the new location and make sure the permissions are set correctly.
echo "Copying Images..."
copywperm "$images" "$newversionfolder"
#copy the pictures folder from the old location to the new location and make sure the permissions are set correctly.
echo "Copying Pictures.."
copywperm "$pictures" "$newversionfolder"
#copy the drawings folder from the old location to the new location and make sure the permissions are set correctly.
echo "Copying drawings"
copywperm "$drawings" "$newversionfolder"
#and for the grand fanale, update the synlink!
echo "Setting new symlink."
ln -sfn $installeddir/$newversionfolder opendcim
#final statement
printf '%s %s %s\n' DB info: $dcimd $dbusername $dbpassword
