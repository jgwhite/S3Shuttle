require 'drb'
require 'thread'
require 'yaml'
require 'logger'


module S3Shuttle # :nodoc:
	
	# DRb Server class maintains a queue of files awaiting upload to Amazon S3 storage
	class Server
		
		CONFIG 	 = "/etc/s3_shuttle/s3_shuttle.yml"
		DEFAULTS = {
			"host"				=> "localhost",
			"port"				=> "26001",
			"queue_path"	=> "/var/s3_shuttle/s3_shuttle.queue",
			"pid_path"		=> "/var/s3_shuttle/s3_shuttle.pid",
			"log_path"		=> "/var/s3_shuttle/s3_shuttle.log"
		}
		
		@@instance = nil
		@@config = nil
		@@running = nil
		@@logger = nil
		
		# Returns the S3Shuttle global configuration
		def self.config
			if @@config.nil?
				@@config = DEFAULTS.dup
				custom_conf = YAML::load_file(CONFIG) rescue nil
				@@config.merge!(custom_conf) if custom_conf
			end
			
			return @@config
		end
		
		# Returns druby uri
		def self.uri
			"druby://#{self.config['host']}:#{self.config['port']}"
		end
		
		# Creates singleton instance of Server and a Drb instance to house it
		def self.start
			@@instance = S3Shuttle::Server.new
			DRb.start_service(self.uri, @@instance)
		end
		
		# Exits current delivery thread if active and exits the process
		def self.stop
			@@instance.delivery_thread.exit if @@instance.delivery_thread.respond_to?(:exit)
			exit
		end
		
		# Determines if Server is running by inspecting the pid file
		def self.running?
			File.exists?(self.config["pid_path"]) && !File.read(self.config["pid_path"]).empty?
		end
		
		# Access to S3Shuttle logger
		def self.logger
			@@logger ||= Logger.new(self.config["log_path"])
		end
		
		# If S3Shuttle is running, returns a new DrbObject, otherwise returns nil
		def self.connection
			if self.running?
				DRb.start_service
				return DRbObject.new(nil, self.uri)
			end
		end
		
		
		attr_reader :delivery_thread
		
		# Server will immediately inspect the queue and begin deliverying pending files
		def initialize
			logger.info(self.inspect + " --- PROCESS STARTED")
			deliver_next if queue.length > 0
		rescue => error
			logger.error(error)
		end
		
		# Takes a Hash containg "filename", "path", "bucket" and optionally "access"
		# and adds it to S3Shuttle's upload queue
		def add(file)
			if file.is_a?(Array)
				file.each { |f| add(f) }
			else
				queue.join(file)
				logger.info(file.inspect + " --- ADDED")
				deliver_next unless delivery_pending?
			end
		rescue => error
			logger.error(error)
		end
		
		# Spawns a new thread to deliver the next awaiting file in the queue
		def deliver_next
			@delivery_pending = true
			file = queue.next
			logger.info(file.inspect + " --- UPLOAD BEGAN")
			@delivery_thread = Thread.new(uploader, file) { |u,f| u.deliver(f) }
		rescue => error
			logger.error(error)
		end
		
		# Callback on completed file delivery, will either kick off next delivery or set idle flag
		def delivered(file)
			logger.info(file.inspect + " --- UPLOAD COMPLETED")
			queue.done(file)
			
			if @queue.length > 0
				deliver_next
			else
				@delivery_pending = false
			end
		rescue => error
			logger.error(error)
		end
		
		# Returns true if there is currently a delivery in progress
		def delivery_pending?
			@delivery_pending
		rescue => error
			logger.error(error)
		end
		
		# Returns instance of Uploader, inited with access credentials
		def uploader
			@uploader ||= S3Shuttle::Uploader.new(self, self.class.config["credentials"])
		rescue => error
			logger.error(error)
		end
		
		# Returns instance Queue, inited with its .queue path
		def queue
			@queue ||= S3Shuttle::Queue.new(self, self.class.config["queue_path"])
		rescue => error
			logger.error(error)
		end
		
		# Returns S3Shuttle's global logger instance
		def logger
			S3Shuttle::Server.logger
		end
		
	end
	
end
