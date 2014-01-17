require 'spec_helper'

describe SumoControl, :vcr do
  let(:sumo){SumoControl.new(user, password)}

  let(:user){'test@example.com'}
  let(:password){'password'}

  let(:collector_id){'4216085'}
  let(:host_ip){'192.168.11.23'}
  let(:category){'apache'}
  let(:name){"#{host_name}_#{category}"}
  let(:log_file_path){'/var/log/apache2/access_log'}

  let!(:source_definition) do
    sumo.register(collector_id, id_file_path) do |source|
      # Tracking
      source.category = category
      source.name = name
      source.source_type = "RemoteFile"
      source.remote_path = log_file_path
      source.filters = SumoControl::COMMON_APACHE_FILTERS

      # SSH Connection
      source.auth_method = 'key'
      source.remote_user = 'root'
      source.remote_password = nil
      source.remote_hosts = [host_ip]
      source.remote_port = 22
      source.key_path = '/home/sumo/.ssh/id_rsa'
      source.key_password = nil
    end
  end
  subject{source_definition}

  let(:fixture_path){File.expand_path('../fixtures', __FILE__)}

  context 'registering a new source', :vcr => {:cassette_name => 'new_source', :record => :new_episodes} do
    let(:host_name){'test_new_source'}
    let(:id_file_path){fixture_path + '/new_sumo_source.txt'}
    let(:expected_source_id){7868940}

    its(:id){should eql(expected_source_id)}
    its(:version){should eql('"f013d0a5fbd41f5411e1f654cbbbd6df"')}

    it "writes the source id from the response to a file" do
      File.read(id_file_path).should =~ /"id": #{expected_source_id},/
    end

    after(:each){File.delete(id_file_path)}
  end

  context 'registering an existing source', :vcr => {:cassette_name => 'existing_source', :record => :new_episodes} do
    let(:host_name){'test_existing_source'}
    let(:id_file_path){fixture_path + '/existing_sumo_source.txt'}
    let(:expected_source_id){7858761}

    its(:id){should eql(expected_source_id)}
    its(:version){should eql('"0812ec7ee0baa811ba9cf63b0d2b3f7b"')}

    it "writes the source id from the response to a file" do
      File.read(id_file_path).should =~ /"id": #{expected_source_id},/
    end

    after(:each) do
      File.open(id_file_path, 'w') do |f|
        f.write("#{expected_source_id}\n") #reset file
      end
    end
  end
end
