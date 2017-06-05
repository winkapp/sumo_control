require 'spec_helper'

describe SumoControl, :vcr do
  let(:sumo) { SumoControl.new(sumo_access_id: sumo_access_id, sumo_access_key: sumo_access_key) }

  let(:sumo_access_id) { 'testuser' }
  let(:sumo_access_key) { 'testpassword' }

  context 'SumoLogic Service Collectors', vcr: {cassette_name: 'collectors'} do

    let(:name) { 'Test Collector' }
    let(:description) { 'Test Description' }
    let(:category) { 'Test Category' }
    let(:expected_collector_id) { 116769034 }

    specify 'should register a new collector' do
      c_def = sumo.register_collector(name, description, category)
      expect(c_def.id).to eql expected_collector_id
      expect(c_def.name).to eql name
      expect(c_def.description).to eql description
      expect(c_def.category).to eql category
    end

    specify 'should update an existing collector' do
      c_def = sumo.register_collector(name, description, category)
      expect(c_def.id).to eql expected_collector_id

      expect_any_instance_of(SumoControl::Client)
        .to receive(:update_collector)
        .with(SumoControl::CollectorDefinition.new(collector_type: 'Hosted', name: name, description: description, category: category))
        .and_call_original

      updated_desc = 'Test Updated Description'
      updated_cat = 'Test Updated Category'

      c_def_updated = sumo.register_collector(name, updated_desc, updated_cat)
      expect(c_def_updated.id).to eql expected_collector_id
      expect(c_def_updated.name).to eql name
      expect(c_def_updated.description).to eql updated_desc
      expect(c_def_updated.category).to eql updated_cat
    end

    specify 'should delete collector' do
      expect_any_instance_of(SumoControl::Client)
        .to receive(:delete_collector)
        .with(SumoControl::CollectorDefinition.new(name: name))
        .and_call_original
      sumo.delete_collector(name)
    end

    specify 'should find a collector by name' do
      collector = sumo.find_collector(name)
      expect(collector.name).to eql(name)
      expect(collector.category).to eql(category)
      expect(collector.description).to eql(description)
      expect(collector.id).to eql(expected_collector_id)
    end

  end

  context 'SumoLogic Service New File Source', vcr: {cassette_name: 'new_source'} do
    let(:collector_id) { '4216085' }
    let(:host_ip) { '192.168.11.23' }
    let(:category) { 'apache' }
    let(:name) { "#{host_name}_#{category}" }
    let(:log_file_path) { '/var/log/apache2/access_log' }
    let(:fixture_path) { File.expand_path('../fixtures', __FILE__) }

    let(:host_name) { 'test_new_source' }
    let(:id_file_path) { fixture_path + '/new_sumo_source.txt' }
    let(:expected_source_id) { 7868940 }

    let(:source_definition) {
      SumoControl::SourceDefinition.new(
        category: category,
        name: name,
        source_type: 'RemoteFile',
        remote_path: log_file_path,
        filters: SumoControl::COMMON_APACHE_FILTERS,
        auth_method: 'key',
        remote_user: 'root',
        remote_password: nil,
        remote_hosts: [host_ip],
        remote_port: 22,
        key_path: '/home/sumo/.ssh/id_rsa',
        key_password: nil
      )
    }

    after(:each) { File.delete(id_file_path) }

    specify 'should register a new file source' do
      updated_source_definition = sumo.register_file_source(collector_id, source_definition, id_file_path)
      expect(updated_source_definition.id).to eql expected_source_id
      expect(updated_source_definition.version).to eql '"f013d0a5fbd41f5411e1f654cbbbd6df"'
      expect(File.read(id_file_path)).to match /"id": #{expected_source_id},/
    end
  end

  context 'SumoLogic Service Existing File Source', vcr: {cassette_name: 'existing_source'} do
    let(:collector_id) { '4216085' }
    let(:host_ip) { '192.168.11.23' }
    let(:category) { 'apache' }
    let(:name) { "#{host_name}_#{category}" }
    let(:log_file_path) { '/var/log/apache2/access_log' }
    let(:fixture_path) { File.expand_path('../fixtures', __FILE__) }

    let(:host_name) { 'test_existing_source' }
    let(:id_file_path) { fixture_path + '/existing_sumo_source.txt' }
    let(:expected_source_id) { 7858761 }

    let(:source_definition) {
      SumoControl::SourceDefinition.new(
        category: category,
        name: name,
        source_type: 'RemoteFile',
        remote_path: log_file_path,
        filters: SumoControl::COMMON_APACHE_FILTERS,
        auth_method: 'key',
        remote_user: 'root',
        remote_password: nil,
        remote_hosts: [host_ip],
        remote_port: 22,
        key_path: '/home/sumo/.ssh/id_rsa',
        key_password: nil
      )
    }

    after(:each) { File.delete(id_file_path) }

    specify 'update an existing file source' do
      updated_source_definition = sumo.register_file_source(collector_id, source_definition, id_file_path)
      expect(updated_source_definition.id).to eql expected_source_id
      expect(updated_source_definition.version).to eql '"0812ec7ee0baa811ba9cf63b0d2b3f7b"'
      expect(File.read(id_file_path)).to match /"id": #{expected_source_id},/
    end
  end

  context 'SumoLogic Service S3 Sources', vcr: {cassette_name: 'sources'} do
    let(:name) { 'test_source' }
    let(:description) { 'test_description' }
    let(:category) { 'test_category' }
    let(:bucket) { 'test-bucket' }
    let(:path) { '*/test.log' }
    let(:awsid) { 'TESTAWSID' }
    let(:awskey) { 'TESTAWSKEY' }
    let(:collector_id) { 116771369 }
    let(:expected_source_id) { 194207840 }

    specify 'should register a new s3 source' do
      s_def = sumo.register_s3_source(collector_id, name, description, category, bucket, path, awsid, awskey)
      expect(s_def.id).to eql expected_source_id
      expect(s_def.name).to eql name
      expect(s_def.version).to eql '"e0f1ecb5663fbf8db4a3b4d11e1abd0a"'
      expect(s_def.category).to eql category
      expect(s_def.description).to eql description
      expect(s_def.third_party_ref['resources'].first['path']['bucketName']).to eql bucket
      expect(s_def.third_party_ref['resources'].first['path']['pathExpression']).to eql path
      expect(s_def.third_party_ref['resources'].first['authentication']['awsId']).to eql awsid
      expect(s_def.third_party_ref['resources'].first['authentication']['awsKey']).to eql '********'
    end

    specify 'should update an existing s3 source' do
      s_def = sumo.register_s3_source(collector_id, name, description, category, bucket, path, awsid, awskey)
      expect(s_def.id).to eql expected_source_id
      expect(s_def.name).to eql name
      expect(s_def.version).to eql '"e0f1ecb5663fbf8db4a3b4d11e1abd0a"'
      expect(s_def.category).to eql category
      expect(s_def.description).to eql description
      expect(s_def.third_party_ref['resources'].first['path']['bucketName']).to eql bucket
      expect(s_def.third_party_ref['resources'].first['path']['pathExpression']).to eql path
      expect(s_def.third_party_ref['resources'].first['authentication']['awsId']).to eql awsid

      expect_any_instance_of(SumoControl::Client)
        .to receive(:update_source)
        .with(collector_id, s_def)
        .and_call_original

      s_def_updated = sumo.register_s3_source(collector_id, name, 'test_updated_description', 'test_updated_category', 'test-updated-bucket', '*/test-updated.log', nil, nil, 60000, true)
      expect(s_def_updated.id).to eql expected_source_id
      expect(s_def_updated.name).to eql name
      expect(s_def_updated.category).to eql 'test_updated_category'
      expect(s_def_updated.description).to eql 'test_updated_description'
      expect(s_def_updated.third_party_ref['resources'].first['path']['bucketName']).to eql 'test-updated-bucket'
      expect(s_def_updated.third_party_ref['resources'].first['path']['pathExpression']).to eql '*/test-updated.log'
      expect(s_def_updated.third_party_ref['resources'].first['authentication']['awsId']).to eql awsid
      expect(s_def_updated.scan_interval).to eql 60000
      expect(s_def_updated.paused).to be true
    end

    specify 'should delete source' do
      expect_any_instance_of(SumoControl::Client)
        .to receive(:delete_source)
        .with(collector_id, SumoControl::SourceDefinition.new(name: name))
        .and_call_original
      sumo.delete_source(collector_id, name)
    end

  end

end

describe SumoControl::Client, :vcr do

  let(:sumoclient) { SumoControl::Client.new(sumo_access_id, sumo_access_key) }

  let(:sumo_access_id) { 'testuser' }
  let(:sumo_access_key) { 'testpassword' }

  context 'SumoLogic Client Collectors', vcr: {cassette_name: 'collectors'} do

    let(:expected_collector_id) { 116769034 }
    let(:name) { 'Test Collector' }

    specify 'should list all collectors' do
      collectors = sumoclient.collectors
      expect(collectors.count).to eql(125)
    end

    specify 'should get a single collector' do
      collector = sumoclient.collector(expected_collector_id)
      expect(collector.id).to eql(expected_collector_id)
      expect(collector.name).to eql(name)
      expect(collector.version).to eql('"9fd1231461b9c092ed1850f698c75a3c"')

      expect { sumoclient.collector(-1) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_invalid
      }
    end

    specify 'should create a new collector' do
      c_def = SumoControl::CollectorDefinition.new(
        collector_type: 'Hosted',
        name: name,
        description: 'Test Description',
        category: 'Test Category'
      )
      collector = sumoclient.create_collector c_def
      expect(collector.id).to eql expected_collector_id
      expect(collector.name).to eql name
      expect(collector.description).to eql c_def.description
      expect(collector.category).to eql c_def.category
      expect { sumoclient.create_collector(c_def) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_duplicate
      }
    end

    specify 'should update an existing collector' do
      c_def = SumoControl::CollectorDefinition.new(
        collector_type: 'Hosted',
        name: name,
        description: 'Test Updated Description',
        category: 'Test Updated Category'
      )
      collector = sumoclient.update_collector c_def
      expect(collector.id).to eql expected_collector_id
      expect(collector.name).to eql name
      expect(collector.description).to eql c_def.description
      expect(collector.category).to eql c_def.category

      fake_c_def = SumoControl::CollectorDefinition.new(
        name: 'Fake Collector Name',
      )
      expect { sumoclient.update_collector(fake_c_def) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_invalid
      }
    end

    specify 'should delete a collector' do
      collector_definition = SumoControl::CollectorDefinition.new(
        name: name,
      )
      expect(sumoclient.connection).to receive(:delete).and_call_original
      sumoclient.delete_collector(collector_definition)
      fake_c_def = SumoControl::CollectorDefinition.new(
        name: 'Fake Collector Name',
      )
      expect { sumoclient.delete_collector(fake_c_def) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_invalid
      }
    end
  end


  context 'SumoLogic Client Sources', vcr: {cassette_name: 'sources'} do

    let(:collector_id) { 116771369 }
    let(:expected_source_id) { 194207840 }
    let(:name) { 'test_source' }

    specify 'should list all sources' do
      sources = sumoclient.sources(collector_id)
      expect(sources.count).to eql 1
      expect(sources[0].id).to eql expected_source_id
    end

    specify 'should get a single source' do
      source = sumoclient.source(collector_id, expected_source_id)
      expect(source.id).to eql expected_source_id
      expect(source.name).to eql name
      expect(source.version).to eql '"e0f1ecb5663fbf8db4a3b4d11e1abd0a"'

      expect { sumoclient.source(collector_id, -1) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_invalid
      }
    end

    specify 'should create a new source' do

      s_def = SumoControl::SourceDefinition.new(
        category: 'test_category',
        description: 'test_description',
        name: name,
        source_type: 'Polling',
        third_party_ref: {
          resources: [
            {
              serviceType: 'AwsS3Bucket',
              path: {
                type: 'S3BucketPathExpression',
                bucketName: 'test-bucket',
                pathExpression: '*/test.log'
              },
              authentication: {
                type: 'S3BucketAuthentication',
                awsId: 'TESTAWSID',
                awsKey: 'TESTAWSKEY'
              }
            }
          ]
        },
        scan_interval: 300000,
        paused: false
      )
      source = sumoclient.create_source(collector_id, s_def)

      expect(source.id).to eql expected_source_id
      expect(source.category).to eql s_def.category
      expect(source.description).to eql s_def.description
      expect(source.name).to eql name
      expect(source.source_type).to eql s_def.source_type
      expect(source.third_party_ref['resources'].first['path']['bucketName']).to eql s_def.third_party_ref[:resources].first[:path][:bucketName]
      expect(source.third_party_ref['resources'].first['path']['pathExpression']).to eql s_def.third_party_ref[:resources].first[:path][:pathExpression]
      expect(source.scan_interval).to eql s_def.scan_interval
      expect(source.paused).to eql s_def.paused

      expect { sumoclient.create_source(collector_id, s_def) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_duplicate
      }
    end

    specify 'should update an existing source' do
      s_def = SumoControl::SourceDefinition.new(
        category: 'test_updated_category',
        description: 'test_updated_description',
        name: name,
        source_type: 'Polling',
        third_party_ref: {
          resources: [
            {
              serviceType: 'AwsS3Bucket',
              path: {
                type: 'S3BucketPathExpression',
                bucketName: 'test-updated-bucket',
                pathExpression: '*/test-updated.log'
              },
              authentication: {
                type: 'S3BucketAuthentication',
                awsId: 'TESTAWSID',
                awsKey: 'TESTAWSKEY'
              }
            }
          ]
        },
        scan_interval: 60000,
        paused: true
      )
      source = sumoclient.update_source(collector_id, s_def)
      expect(source.id).to eql expected_source_id
      expect(source.category).to eql s_def.category
      expect(source.description).to eql s_def.description
      expect(source.name).to eql name
      expect(source.source_type).to eql s_def.source_type
      expect(source.third_party_ref['resources'].first['path']['bucketName']).to eql s_def.third_party_ref[:resources].first[:path][:bucketName]
      expect(source.third_party_ref['resources'].first['path']['pathExpression']).to eql s_def.third_party_ref[:resources].first[:path][:pathExpression]
      expect(source.scan_interval).to eql s_def.scan_interval
      expect(source.paused).to eql s_def.paused

      fake_s_def = SumoControl::SourceDefinition.new(
        name: 'Fake_Source_Name',
      )
      expect { sumoclient.update_source(collector_id, fake_s_def) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_invalid
      }
    end

    specify 'should delete a source' do
      s_def = SumoControl::SourceDefinition.new(
        name: name,
      )
      expect(sumoclient.connection).to receive(:delete).and_call_original
      sumoclient.delete_source(collector_id, s_def)
      fake_s_def = SumoControl::SourceDefinition.new(
        name: 'Fake_Source_Name',
      )
      expect { sumoclient.delete_source(collector_id, fake_s_def) }.to raise_error(SumoControl::Error) { |error|
        expect(error).to be_invalid
      }
    end
  end

end
