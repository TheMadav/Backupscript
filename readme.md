#Readme

##Purpose

This script can be used to automatically download specific files, like backups, from webservers via FTP. It does **not** create backups as the name might imply.

To automatically download files, run this script as a *launch agent* (Mac OS), cron (Linux etc.) or Task Scheduler (Windows).

##Getting started

Before you run the script the first time, you should enter your website information in the **sites.yml**. Two example configuration are already in there to show the parameters you can use:

-**name**: The name of the website (will be used in the logfile as well as to name the folder). You can use the same name several times, e.g. if you want to download sql scripts daily and zip files weekly.

-**ftpUrl:** Is the ftp-server that the script should connect to, often the base url of your website.

-**backupPath:** The ftp directory where your files are saved, e.g. */html/backups*

-**username:** Your FTP username

-**password:** Your FTP password

-**fileExtensions:** The file extension that you want to download, e.g. *zip* or *sql*

-**weekdays:** On which days should the script run for each configured site, (0 - sunday, 6 saturday). If you want to use several days, simply add additional lines.

*Optional Parameters*
-**backupUrl :** If you have a script on your server that backups your site, you can trigger it from your local script instead of using something like cron.
-**keepForDays:** The backup script will automatically delete old files after a certain period of time. The default value is 100 days. If you enter 0 your files should be kept indefinitely. 

##Testing configurations

You can run the script with two arguments to test configurations.

`ruby downloadbackup.rb -test` will trigger every configuration, independent of the assigned weekdays.

`ruby downloadbackup.rb -testsite NAME` will run **only** the specified site (although if you have several configurations with the same name, all of them will run). 