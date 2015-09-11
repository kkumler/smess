# coding: UTF-8
smess_path = File.expand_path('.', File.dirname(__FILE__))
$:.unshift(smess_path) if File.directory?(smess_path) && !$:.include?(smess_path)

require 'mail'
require 'savon'
require 'active_support'
require 'active_support/core_ext'

require "smess/version"
require 'smess/logging'
require 'smess/output'
require 'smess/utils'
require 'smess/sms'
require 'smess/outputs/http_base'
require 'smess/outputs/auto'
require 'smess/outputs/ipx'
require 'smess/outputs/ipxus'
require 'smess/outputs/card_board_fish'
require 'smess/outputs/clickatell'
require 'smess/outputs/smsglobal'
require 'smess/outputs/global_mouth'
require 'smess/outputs/mblox'
require 'smess/outputs/twilio'
require 'smess/outputs/iconectiv'
require 'smess/outputs/test'

require 'string_ext'

module Smess

  def self.new(*args)
    Sms.new(*args)
  end

  def self.named_output_instance(name)
    output_class_name = config.configured_outputs.fetch(name)[:type].to_s.camelize
    conf = config.configured_outputs[name][:config]
    "Smess::#{output_class_name}".constantize.new(conf)
  end

  def self.config
    @config ||= Config.new
  end

  def self.reset_config
    @config = Config.new
  end

  def self.configure
    yield(config)
  end

  class Config
    attr_accessor :nothing, :default_output, :default_sender_id, :default_sender_id, :country_codes, :output_types, :configured_outputs, :output_by_country_code

    def initialize
      @nothing = false
      @default_output = :global_mouth
      @default_sender_id = "Smess"
      @country_codes = [1, 20, 212, 33, 34, 44, 46, 49, 594, 966, 971]
      @output_types = %i{auto card_board_fish clickatell global_mouth iconectiv mblox smsglobal twilio}
      @configured_outputs = {test: {type: :test, config: nil}}
      @output_by_country_code = {
        "1"   => :iconectiv,        # USA
        "1242"=> :global_mouth,     # Bahamas
        "1246"=> :global_mouth,     # Barbados
        "1264"=> :global_mouth,     # Anguilla
        "1268"=> :global_mouth,     # Antigua and Barbuda
        "1284"=> :global_mouth,     # British Virgin Islands
        "1345"=> :global_mouth,     # Cayman Islands
        "1441"=> :clickatell,       # Bermuda
        "1473"=> :global_mouth,     # Grenada
        "1649"=> :global_mouth,     # Turks and Caicos Islands
        "1664"=> :global_mouth,     # Montserrat
        "1670"=> :global_mouth,     # Northern Mariana Islands
        "1671"=> :global_mouth,     # Guam
        "1684"=> :global_mouth,     # American Samoa
        "1758"=> :global_mouth,     # Saint Lucia
        "1767"=> :global_mouth,     # Dominica
        "1784"=> :global_mouth,     # Saint Vincent and the Grenadines
        "1787"=> :global_mouth,     # Puerto Rico
        "1809"=> :global_mouth,     # Dominican Republic
        "1868"=> :global_mouth,     # Trinidad and Tobago
        "1869"=> :global_mouth,     # Saint Kitts and Nevis
        "1876"=> :global_mouth,     # Jamaica
        "20"  => :global_mouth,     # Egypt
        "212" => :card_board_fish,  # Morocco
        "33"  => :global_mouth,     # France
        "34"  => :global_mouth,     # Spain
        "44"  => :global_mouth,     # Great Britain
        "46"  => :global_mouth,     # Sweden
        "49"  => :global_mouth,     # Germany
        "594" => :global_mouth,     # French Guiana
        "966" => :global_mouth,     # Saudi Arabia
        "971" => :twilio            # United Arab Emirates
      }
    end

    def add_country_code(cc, output=default_output)
      raise ArgumentError.new("Invalid country code") unless cc.to_i.to_s == cc.to_s
      raise ArgumentError.new("Unknown output specified") unless outputs.include? output.to_sym
      output_by_country_code[cc.to_s] = output.to_sym
      true
    end

    def register_output(options)
      name = options.fetch(:name).to_sym
      type = options.fetch(:type).to_sym
      country_codes = options.fetch(:country_codes)
      config = options.fetch(:config)

      raise ArgumentError.new("Duplicate output name") if outputs.include? name
      raise ArgumentError.new("Unknown output type specified") unless output_types.include? type

      configured_outputs[name] = {type: type, config: config}
      country_codes.each do |cc|
        add_country_code(cc, name)
      end
    end

    def outputs
      configured_outputs.keys
    end

  end
end

# httpclient does not send basic auth correctly, or at all.
HTTPI.adapter = :net_http
