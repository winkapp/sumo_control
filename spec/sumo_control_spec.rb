require 'spec_helper'

describe SumoControl, :vcr do
  let(:sumo) do
    Class.new do
      include SumoControl
    end.new
  end

  let(:api_host){'https://api.sumologic.com'}
  let(:user){'test@example.com'}
  let(:password){'password'}

  let(:collector_id){'4216085'}
  let(:host_ip){'192.168.11.23'}
  let(:category){'apache'}
  let(:source){"#{host_name}_#{category}"}
  let(:log_file_path){'/var/log/apache2/access_log'}

  let(:sumo_connection){sumo.conn_sumo(api_host, user, password)}
  let!(:response){sumo.sumo_add_or_update(category, source, host_ip, log_file_path, id_file_path, collector_id, sumo_connection)}
  subject{response}
  let(:actual_source_id){JSON.parse(response.body)['source']['id']}

  let(:fixture_path){File.expand_path('../fixtures', __FILE__)}

  context 'registering a new source', :vcr => {:cassette_name => 'new_source'} do
    let(:host_name){'test_new'}
    let(:id_file_path){fixture_path + '/new_sumo_source.txt'}
    let(:expected_source_id){6732928}

    its(:status){should eql(201)} # created

    it "responds with the source id of the new source" do
      actual_source_id.should eql(expected_source_id)
    end

    it "writes the source id from the response to a file" do
      File.read(id_file_path).should =~ /^#{expected_source_id}$/
    end

    after(:each){File.delete(id_file_path)}
  end

  context 'registering an existing source', :vcr => {:cassette_name => 'existing_source'} do
    let(:host_name){'test_existing'}
    let(:id_file_path){fixture_path + '/existing_sumo_source.txt'}
    let(:expected_source_id){6732930}

    its(:status){should eql(200)} # created

    it "responds with the source id of the new source" do
      actual_source_id.should eql(expected_source_id)
    end

    it "writes the source id from the response to a file" do
      File.read(id_file_path).should =~ /^#{expected_source_id}$/
    end

    after(:each) do
      File.open(id_file_path, 'w') do |f|
        f.write("#{expected_source_id}\n") #reset file
      end
    end
  end
end
