require 'aws/s3'

module S3Shuttle # :nodoc:
	
	class MissingCredentialsError < StandardError; end
	
	# Solo upload thread that calls back to the main server when complete
	class Uploader
		
		ALLOWED_ACCESS_MODES = ["private", "public_read", "public_read_write", "authenticated_read"]
		
		# Takes server instance for callbacks and S3 credentials
		def initialize(server, credentials)
			@server = server
			AWS::S3::Base.establish_connection!(
				:access_key_id			=> credentials["access_key_id"],
				:secret_access_key	=> credentials["secret_access_key"]
			)
		rescue => error
			S3Shuttle::Server.logger.error(error)
		end
		
		# Argument file should be a Hash containing "filename", "path", "bucket" and optionally "access"
		def deliver(file, callback=:delivered)
			options = {}
			(options[:access] = file["access"].to_sym) if ALLOWED_ACCESS_MODES.include?(file["access"])
			
			AWS::S3::S3Object.store(
				file["filename"],		# key
				open(file["path"]),	# data
				file["bucket"],			# bucket
				options
			)
			@server.send(callback, file)
		rescue Exception => error
			S3Shuttle::Server.logger.error(error)
		end
		
	end
	
end
