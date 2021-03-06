require 'spec_helper'

describe Smess do
  describe "#output" do
    let(:sms) {
      Smess.new(
        to: '46701234567',
        message: 'Test SMS',
        originator: 'TestSuite',
        output: "test"
      )
    }
    it "returns a populated Sms when mobule macro is invoked" do
      sms.class.should == Smess::Sms
      sms.to.should == '46701234567'
      sms.output.should == :test
    end
  end

  describe "Config behavior" do

    let(:twilio_options) {
      {
        name: :twilio1,
        country_codes: ["1", "46"],
        type: :twilio,
        config: {
          sid: "AC9bdf5015d8acd1b5f8d4ab92ff001087",
          auth_token: "6a4f328099ed622a704b5a843e9e03af",
          from: "18779597784",
          callback_url: "https://gateway.tricefy.com/mobile_gate/sms_report/from/twilio"
        }
      }
    }

    before(:each) {
      Smess.reset_config
    }

    it "reads config defaults" do
      expect(Smess.config.nothing).to be_false
    end

    it "reads changed config values" do
      Smess.configure do |config|
        config.nothing = true
      end
      expect(Smess.config.nothing).to be_true
    end

    it "can reset config back to defaults" do
      Smess.configure do |config|
        config.nothing = true
      end
      expect(Smess.config.nothing).to be_true
      Smess.reset_config
      expect(Smess.config.nothing).to be_false

    end


    it "can register an output" do
      Smess.configure do |config|
        config.register_output(twilio_options)
      end
      expect(Smess.config.outputs).to include(:twilio1)
    end


    it "can add a country code" do
      Smess.configure do |config|
        config.register_output(twilio_options)
      end
      Smess.configure do |config|
        config.add_country_code(99, twilio_options[:name])
      end
      expect(Smess.config.output_by_country_code["99"]).to eq(twilio_options[:name])
    end

    it "can add a country code without specifying the output" do
      Smess.configure do |config|
        config.default_output = twilio_options[:name]
        config.register_output(twilio_options)
      end
      Smess.configure do |config|
        config.add_country_code("99")
      end
      expect(Smess.config.output_by_country_code["99"]).to eq(Smess.config.default_output)
    end

    it "raises when given a non-numeric country code" do
      expect{
        Smess.configure do |config|
          config.add_country_code("hello")
        end
      }.to raise_error
    end

    it "raises when given an unknown output" do
      expect{
        Smess.configure do |config|
          config.add_country_code("99", :hello)
        end
      }.to raise_error
    end

  end

end
