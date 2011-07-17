# This script downloads backups (or other files) from websites and
# saves them into designated folders.
# Author::   David Freund (malto:dev@davidfreund.de)
# Copyright::  2011 David Freund
# License::   GPL

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

#This class takes the website data, triggers the backup script and downloads the file
class Webseite
  attr_accessor :name, :ftpUrl, :backupUrl, :directory, :username , :passwd, :extension, :folder, :keepForDays, :weekdays
  
  #Creates the basic class and ensures the folder exists
  def initialize(name, ftpUrl, directory, username, passwd, extension, backupUrl = nil, keepForDays = 100, weekdays = [0])
    @name = name
    @ftpUrl = ftpUrl
    @backupUrl = backupUrl
    @directory = directory
    @username = username
    @passwd = passwd
    @folder = LOCALFOLDER+"/"+@name+"/"
    @extension = extension
    @keepForDays = keepForDays
    @weekdays = weekdays
    self.create_if_missing
  end
    
  #Initializes the Backup.
  #Checks if the backup should run today, else aborts.
  def initBackup 
    today = Time.now.wday
    #Do the backup either as planned or in testmode
    if ( 
          (@weekdays.include?(today) && TESTMODE === false) || 
          (TESTMODE === true && TESTSITE.nil?) || 
          (TESTMODE === true && TESTSITE == @name)
      )
      $LOG.info("#{@name} : Backup initiated")  
      self.createBackup unless @backupUrl.nil?
      self.ftpDownload
      self.cleanUp
      $LOG.info("#{@name} : Backup completed")  
    end
  end

  #Calls the backup procedure on the website
  #Can be used instead of a cronjob
  def createBackup
    fetch("#{@backupUrl}", 3000)
    $LOG.info("#{@name} : Backupfile created")  
    sleep 120
  end
  
  #Creates a folder for the backup, if the folder doesn't exist yet
  def create_if_missing  
      if File.exists?(@folder)
        return
      else
        Dir.mkdir(@folder) unless 
        $LOG.info("#{@name} : #{@folder} created")
      end
  end
  
  #Cleans the folder from files older than the livespan specified in the YAML document, standard livespan is 100 days
  def cleanUp
    Dir.chdir(@folder) 
    Dir.foreach(".") do |entry|
       next if entry == "." or entry == ".."
       currentFile = File.stat(entry)
       x = currentFile.atime
      if Time.now - x > 60 * 60 * 24 * @keepForDays 
        $LOG.info("#{@name} : #{entry} reached its lifespan")
        File.delete(entry)
      end
    end
  end
  
  #Downloads and afterwards deletes the file from the server
  def ftpDownload
    ftp = nil
    begin
      timeout( CON_TIMEOUT ) do
        ftp = Net::FTP.new( @ftpUrl )
        ftp.login( @username, @passwd )
        ftp.chdir(@directory)
         $LOG.info("#{@name} : Connected to #{ @ftpUrl}") 
        @filenames = ftp.nlst("*.#{@extension}")

      end
      @filenames.each{|filename|
        timeout( TRANSFER_TIMEOUT ) do
          $LOG.info("#{@name} : Download #{filename}") 
          ftp.getbinaryfile(filename,@folder+"/#{filename}") #Get the file
          ftp.delete(filename)
          $LOG.info{"#{@name} : Deleted on server #{filename}"}
        end
      } unless @filenames.empty?
    rescue Exception => e
      $LOG.error("Error ftp-transfer server: #{@ftpUrl}")
      $LOG.error("Error: #{e}")
      #raise
    ensure
      ftp.close if ftp
      GC.start
      sleep 5
    end
    
  end
  
  #Helper class for the backup creation process
  def fetch(uri_str, limit = 10)
       # You should choose better exception.
       raise ArgumentError, 'HTTP redirect too deep' if limit == 0

       response = Net::HTTP.get_response(URI.parse(uri_str))
       case response
       when Net::HTTPSuccess     then response
       when Net::HTTPRedirection then fetch(response['location'], limit - 1)
       else
         response.error!
       end
     end
     
end

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
