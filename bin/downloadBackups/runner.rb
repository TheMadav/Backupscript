require 'logger'  
require 'yaml'
require 'rexml/document'
include REXML
require '././lib/downloadBackups/website'

module DownloadBackups
  class Runner
    
    def initialize(argv)
      case argv[0]
        when "-test"
          testmode = true
          testsite = nil
        when "-testsite"
          testmode = true
            if ARGV[1].nil?
              puts "No site name given"
              exit 1
            else
              testsite = ARGV[1]
            end
        else
          testmode = false
          testsite = nil
      end
      const_set("TESTMODE", testmode)
      const_set("TESTSITE", testsite)
    end
    
    def run
      month = Time.now.month
      year = Time.now.year
      #Logfile - a new file is created each month
      $LOG = Logger.new(LOCALFOLDER+"/#{year}-#{month}-Backup.log") 
   #Opens the configuration file
      websites = File.open( "sites.yml" )

      #Loads the Websites into an array
      websitesArray = Array.new
      yp = YAML::load_documents( websites ) { |website|
        websitesArray.push( DownloadBackups::Webseite.new(
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
      
    end
  end
end