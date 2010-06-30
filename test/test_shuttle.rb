$LOAD_PATH << File.dirname(__FILE__) + "/../lib"

require 'test/unit'
require 's3_shuttle'
require 'drb'
require 'aws/s3'

class TestShuttle < Test::Unit::TestCase
	
	def test_truth
		assert true
		
		# Test that config comes through correctly
		assert_nothing_raised { S3Shuttle::Server.config }
		assert S3Shuttle::Server.config.is_a?(Hash)
		["host", "port", "queue_path", "pid_path", "log_path", "credentials"].each do |key|
			assert_not_nil S3Shuttle::Server.config[key]
		end
		
		# Test that uri is generated correctly
		assert_nothing_raised { S3Shuttle::Server.uri }
		assert S3Shuttle::Server.uri =~ /druby:\/\/localhost:\d+/
		
		# Test that Server starts without issue
		assert_nothing_raised { S3Shuttle::Server.start }
		assert S3Shuttle::Server.running?
		
		# Test that server is available over druby://
		DRb.start_service
		shuttle = nil
		assert_nothing_raised { shuttle = DRbObject.new(nil, S3Shuttle::Server.uri) }
		assert_not_nil shuttle
		assert shuttle.respond_to?(:add)
		
		# Test add
		# - that queue length has increased
		# - that .queue file has changed
		# - that upload is happening (delivery thread)
		
		# Test that file got delievered
		# - Check .queue is getting shorter
		
		# Check delivery_pending? returns the right thing
		
		# Test files are actually making it up to Amazon
	end
	
end
