require 'rubygems'
require 'json'
require 'logger'

require 'sumo_control/collector_definition'
require 'sumo_control/source_definition'
require 'sumo_control/error'
require 'sumo_control/client'
require 'sumo_control/filters'
require 'sumo_control/source_file'

class SumoControl
  def initialize(access_id=nil, access_key=nil)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger.const_get(ENV['LOG_LEVEL'].upcase) rescue nil || Logger::INFO
    access_id = access_id || ENV['SUMO_ACCESS_ID']
    access_key = access_key || ENV['SUMO_ACCESS_KEY']
    @client = Client.new(access_id, access_key, @logger)
  end

  def register_collector(name, description=nil, category=nil)
    collector_definition = CollectorDefinition.new(
      :collector_type => 'Hosted',
        :name => name,
        :description => description,
        :category => category
    )
    client.create_collector(collector_definition)
  rescue SumoControl::Error => error
    logger.fatal(error) unless error.duplicate?
    client.update_collector(collector_definition)
  end

  def delete_collector(name)
    client.delete_collector(CollectorDefinition.new(:name => name))
  rescue SumoControl::Error => error
    logger.fatal(error) unless error.invalid?
  end

  def register_s3_source(collector_id, name, description=nil, category=nil, bucket=nil, path=nil, aws_id=nil, aws_key=nil, scan_interval=300000, paused=false)
    path_h = {
      type: 'S3BucketPathExpression'
    }
    path_h[:bucketName] = bucket unless bucket.nil?
    path_h[:pathExpression] = path unless path.nil?
    authentication = {
      type: 'S3BucketAuthentication'
    }
    authentication[:awsId] = aws_id unless aws_id.nil?
    authentication[:awsKey] = aws_key unless aws_key.nil?

    third_part_ref = {
      resources: [
        {
          serviceType: 'AwsS3Bucket',
          path: path_h,
          authentication: authentication
        }
      ]
    }
    source_definition = SourceDefinition.new(
      category: category,
      description: description,
      name: name,
      source_type: 'Polling',
      third_party_ref: third_part_ref,
      scan_interval: scan_interval,
      paused: paused
    )
    register_source(collector_id, source_definition)
  rescue SumoControl::Error => error
    logger.fatal(error)
  end

  def register_file_source(collector_id, source_definition, source_json_path)
    updated_source_definition = register_source(collector_id, source_definition)
    store_source(updated_source_definition, source_json_path)

    updated_source_definition
  rescue SumoControl::Error => error
    logger.fatal(error)
  end

  def delete_source(collector_id, name)
    client.delete_source(collector_id, SourceDefinition.new(name: name))
  rescue SumoControl::Error => error
    logger.fatal(error) unless error.invalid?
  end

private

  attr_reader :client, :logger

  def register_source(collector_id, source_definition)
    client.create_source(collector_id, source_definition)
  rescue SumoControl::Error => error
    raise unless error.duplicate?
    client.update_source(collector_id, source_definition)
  end

  def remote_source_definition(collector_id, source_definition)
    client.source(collector_id, lookup_source_id(collector_id, source_definition))
  end

  def lookup_source_id(collector_id, source_definition)
    client.sources(collector_id).detect{|remote_source| remote_source == source_definition}.id
  end

  def store_source(source_definition, file_path)
    SourceFile.new(file_path).write(source_definition)
  end
end
