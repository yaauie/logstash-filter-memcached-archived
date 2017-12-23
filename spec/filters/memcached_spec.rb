# encoding: utf-8
require_relative '../spec_helper'
require "logstash/filters/memcached"

LogStash::Logging::Logger::configure_logging("TRACE")

describe LogStash::Filters::Memcached do
  describe "Set to Hello World" do
    let(:config) do <<-CONFIG
      filter {
        memcached {
          hosts => ["localhost:11211"]
          set => {
            "[answer]" => "success/%{success}/answer"
          }
          get => {
            "success/%{success}/answer" => "[ultimate][answer]"
          }
        }
      }
    CONFIG
    end

    sample("answer" => "42", "success" => "true") do
      expect(subject).to include("answer")
      expect(subject.get('answer')).to eq("42")

      expect(subject).to include("ultimate")
      expect(subject.get("ultimate")).to eq("answer" => "42")
    end
  end
end
