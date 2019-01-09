# encoding: utf-8
require_relative '../spec_helper'
require "logstash/filters/memcached"

LogStash::Logging::Logger::configure_logging("TRACE")

describe LogStash::Filters::Memcached do
  subject(:memcached_filter) { described_class.new(config) }
  let(:cache) { double('memcached') }
  before(:each) do
    allow(memcached_filter).to receive(:establish_connection).and_return(cache)
    allow(memcached_filter).to receive(:close)
    memcached_filter.register
  end

  after(:each) do
    memcached_filter.close
  end

  describe "#get" do
    let(:event) { ::LogStash::Event.new(data) }
    let(:config) do
      {
        "hosts" => ["localhost:11211"],
        "get" => { "success/%{success}/answer" => "[ultimate][answer]" }
      }
    end
    let(:data) { { "success" => "true" } }

    it "retrieves data from memcache" do
      expect(cache).to receive(:get_multi).with(["success/true/answer"]).and_return({"success/true/answer" => "42"})
      expect(memcached_filter).to receive(:filter_matched)
      memcached_filter.filter(event)
      expect(event.get("ultimate")).to eq("answer" => "42")
    end

    context 'when memcached does not hold the value' do
      before do
        expect(cache).to receive(:get_multi).with(["success/true/answer"]).and_return({"success/true/answer" => nil})
      end

      it 'does not invoke `filter_matched`' do
        expect(memcached_filter).to_not receive(:filter_matched)
        memcached_filter.filter(event)
      end

      it 'does not populate the value' do
        memcached_filter.filter(event)
        memcached_filter(event.include?("ultimate")).to be false
      end
    end
  end

  describe "#set" do
    let(:event) { ::LogStash::Event.new(data) }
    let(:config) do
      {
        "hosts" => ["localhost:11211"],
        "set" => { "[answer]" => "success/%{success}/answer" },
      }
    end
    before(:each) do
      allow(cache).to receive(:multi) {|&b| b.call }
      allow(cache).to receive(:set)
    end

    context 'when the event includes the value to set' do
      let(:data) { { "answer" => "42", "success" => "true" } }

      it "sets data on memcached" do
        expect(cache).to receive(:set).with("success/true/answer", "42")
        memcached_filter.filter(event)
      end

      it 'invokes `filter_matched`' do
        expect(memcached_filter).to receive(:filter_matched)
        memcached_filter.filter(event)
      end
    end

    context 'when the event does not include the value being set' do
      let(:data) { { "success" => "true" } }

      it 'does not set data on memcached' do
        expect(cache).to_not receive(:set)
        memcached_filter.filter(event)
      end

      it 'does not invoke `filter_matched`' do
        expect(memcached_filter).to_not receive(:filter_matched)
        memcached_filter.filter(event)
      end
    end
  end
end
