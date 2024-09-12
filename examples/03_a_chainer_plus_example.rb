class RakeCommander::Custom::ChainerPlus < RakeCommander::Custom::Chainer
  TARGET_TASK = 'examples:chained_plus'.freeze

  desc "Uses rake (or raked) to invoke #{TARGET_TASK}"
  task :chainer_plus

  # Disable using defaults when options are not invoked.
  options_with_defaults false

  # Update option description
  option_reopen :chain, desc: "Calls: '< rake|raked > #{TARGET_TASK} task'"
  # Extend with new options
  option \
    :e, '--exit-on-error', TrueClass,
    desc: "Whether #{TARGET_TASK} should just exit on 'missing argument' error (or raise an exception)"
  option :o, '--hello NAME', String, desc: 'It greets.'

  # Make it default to `exit 1` when there are errors
  error_on_options false
  # Let it trigger/raise the error when an unknown option is used!
  error_on_options true, error: RakeCommander::Options::Error::InvalidArgument

  def task(*_args)
    puts "Hello #{options[:o]}!!" if options[:o]
    options[:m] = :system unless options[:m]
    super
  end

  # We add the extended arguments at the beginning
  def subcommand_arguments
    [].tap do |args|
      args << '--exit-on-error' if options[:e]
    end.concat(super)
  end
end
