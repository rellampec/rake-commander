class RakeCommander::Custom::ChainedPlus < RakeCommander::Custom::Chained
  desc 'A task+ you want to chain to'
  task :chained_plus

  option_remove :say
  option :e, '--exit-on-error', TrueClass, desc: 'If it should just exit on "missing argument" error or raise an exception'
  # Move option to the end, make **required** the argument (SOMETHING) as well as the option itself.
  option :s, '--say SOMETHING', "It says 'something'", required: true

  error_on_options error: RakeCommander::Options::Error::MissingArgument do |err, _argv, results, _leftovers|
    msg  = "Results when 'missing argument' error was raised"
    msg << " on option '#{err.option.name_full}'" if err.option
    puts msg
    pp results
    !results[:e]
  end
end