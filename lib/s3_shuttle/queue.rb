require 'yaml'


module S3Shuttle # :nodoc:
	
	# Wrapper class that reads from and writes to our queue file
	class Queue
		
		# Takes server instance for callbacks and path for storing queue
		def initialize(server, path)
			@server = server
			@path = path
			@queue = YAML::load_file(path) || []
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
		# Adds a file Hash to the queue and writes it to .queue file
		def join(file)
			unless @queue.include?(file)
				@queue.push(file)
				write!
			end
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
		# Returns next item in queue
		def next
			@queue.first
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
		# Will permenantly remove a file from the queue, normally when it's delivery is completed
		def done(file)
			@queue.delete(file)
			write!
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
		# Returns the number of items in the queue
		def length
			@queue.length
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
		
		protected
		
		# Writes .queue file to disk
		def write!
			open(@path, "w") { |f| f << @queue.to_yaml }
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
	end
	
end
