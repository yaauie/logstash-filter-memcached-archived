# encoding: utf-8
require_relative '../spec_helper'
require "logstash/filters/memcached"

LogStash::Logging::Logger::configure_logging("TRACE")

describe LogStash::Filters::Memcached do
  subject { described_class.new(config) }
  let(:cache) { double('memcached') }
  before(:each) do
    allow(subject).to receive(:establish_connection).and_return(cache)
    allow(subject).to receive(:close)
    subject.register
  end

  after(:each) do
    subject.close
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
      subject.filter(event)
      expect(event.get("ultimate")).to eq("answer" => "42")
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
    let(:data) { { "answer" => "42", "success" => "true" } }
    before(:each) { allow(cache).to receive(:multi) {|&b| b.call } }

    it "sets data on memcache" do
      expect(cache).to receive(:set).with("success/true/answer", "42")
      subject.filter(event)
    end
  end
end
