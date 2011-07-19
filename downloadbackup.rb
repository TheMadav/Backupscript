# This script downloads backups (or other files) from websites and
# saves them into designated folders.
# Author::   David Freund (mailto:dev@davidfreund.de)
# Copyright::  2011 David Freund
# License::   BSD (see license.md)

require 'rubygems'
require 'net/ftp'
require 'fileutils'
require 'date'
require 'timeout'
require 'logger'  
require 'net/http'
require 'uri'
require 'yaml'
require 'rexml/document'
include REXML

#Folder where the files and logs are saved, usually the same folder as the script is in.
LOCALFOLDER = File.expand_path(Dir.getwd)
#Connection Timeout for the FTP Transfer
CON_TIMEOUT      = 30
#Timeout for the file transfer
TRANSFER_TIMEOUT = 1200

#Testmode, will check every website, independent of weekday
case ARGV[0]
  when "-test"
    TESTMODE = true
    TESTSITE = nil
  when "-testsite"
    TESTMODE = true
      if ARGV[1].nil?
        puts "No site name given"
        exit 1
      else
        TESTSITE = ARGV[1]
      end
  else
    TESTMODE = false
    TESTSITE = nil
end

month = Time.now.month
year = Time.now.year
#Logfile - a new file is created each month
$LOG = Logger.new(LOCALFOLDER+"/#{year}-#{month}-Backup.log") 



#Opens the configuration file
websites = File.open( "sites.yml" )

#Loads the Websites into an array
websitesArray = Array.new
yp = YAML::load_documents( websites ) { |website|
  websitesArray.push( Webseite.new(
      website['name'],
      website['ftpUrl'],
      website['backupPath'],
      website['username'],
      website['password'],
      website['fileExtensions'],
      website['backupUrl'],
      website['keepForDays'],
      website['weekdays'])
  )
}
$LOG.info("--------- STARTING TODAYS BACKUP------------") 
#Triggers the Backup for each Website
websitesArray.each{ |website|
  website.initBackup()
  }
  $LOG.info("--------- COMPLETED TODAYS BACKUP------------")
