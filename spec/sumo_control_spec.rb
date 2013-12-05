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
      source.category = category
      source.name = name
      source.remote_host = host_ip
      source.remote_path = log_file_path
      source.filters = SumoControl::COMMON_APACHE_FILTERS
    end
  end
  subject{source_definition}

  let(:fixture_path){File.expand_path('../fixtures', __FILE__)}

  context 'registering a new source', :vcr => {:cassette_name => 'new_source'} do
    let(:host_name){'test_new'}
    let(:id_file_path){fixture_path + '/new_sumo_source.txt'}
    let(:expected_source_id){6732928}

    its(:id){should eql(expected_source_id)}
    its(:version){should eql('"db981a9bde6922e0f0e564c004f15b57"')}

    it "writes the source id from the response to a file" do
      File.read(id_file_path).should =~ /^#{expected_source_id}$/
    end

    after(:each){File.delete(id_file_path)}
  end

  context 'registering an existing source', :vcr => {:cassette_name => 'existing_source'} do
    let(:host_name){'test_existing'}
    let(:id_file_path){fixture_path + '/existing_sumo_source.txt'}
    let(:expected_source_id){6732930}

    its(:id){should eql(expected_source_id)}
    its(:version){should eql('"33bdab4d61bef9dc4a9358b422258d01"')}

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
