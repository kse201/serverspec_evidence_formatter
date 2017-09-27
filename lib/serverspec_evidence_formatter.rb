# require "serverspec_evidence_formatter/version"

require 'date'
require 'erb'

require 'rspec'
require 'rspec/core/formatters'
require 'specinfra'
require 'serverspec/version'
require 'serverspec/type/base'
require 'serverspec/type/command'
RSpec::Support.require_rspec_core "formatters/base_text_formatter"

class ServerspecEvidenceFormatter < RSpec::Core::Formatters::BaseTextFormatter
  RSpec::Core::Formatters.register self,
                                   :example_passed,
                                   :example_pending,
                                   :example_failed

  def initialize(output)
    super
    @seq = 0
    @timestamp = DateTime.now.strftime('%Y%m%d_%H%M%S')
    @evidence_path = 'evidence'
    @report_format = 'report_format.erb'

    # node = ENV['TARGET_HOST'] || Specinfra.configration.host
    @evidence_root = File.join(@evidence_path, @timestamp)
    FileUtils.mkdir_p(@evidence_root)
  end

  def example_passed(notification)
    write_evidence(notification.example, 'success')
  end

  def example_pending(notification)
    write_evidence(notification.example, 'pending')
  end

  def example_failed(notification)
    write_evidence(notification.example, 'failed', notification.exception)
  end

  def write_evidence(example, result, exception = nil)
    @seq += 1
    erb = ERB.new(File.read(File.expand_path("../#{@report_format}", __FILE__)), nil, '-')

    description = example.metadata[:description]
    stdout = example.metadata[:stdout]
    command = command_normalize(example.metadata[:command])

    resource = example.metadata[:described_class]

    if resource.is_a? Serverspec::Type::Command
      stderr = resource.stderr.to_s
      exit_status = resource.exit_status.to_s
    end

    open("#{@evidence_root}/#{format('%06d', @seq)}.txt", 'w') do |io|
      io.puts erb.result(binding)
    end
  end

  @private

  def command_normalize(command)
    # double quart is added.
    "/bin/sh -c \"#{Regexp.last_match[1].delete('\\')}\"" if command =~ %r{^\/bin\/sh -c (.+)$}
  rescue
    command.dup
  end
end
