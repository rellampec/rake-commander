require 'pp'
class RakeCommander::Custom::ChainedPlus < RakeCommander::Custom::Chained
  desc 'A task+ you want to chain to'
  task :chained_plus

  option_remove :say
  option :e, '--exit-on-error', TrueClass, desc: 'If it should just exit on "missing argument" error or raise an exception'
  # Move option to the end, make **required** the argument (SOMETHING) as well as the option itself.
  option :s, '--say SOMETHING', "It says 'something'", required: true
  option :y, '--no-way', FalseClass, "It returns 'true' when used"

  error_on_options error: RakeCommander::Options::Error::MissingArgument do |err, _argv, results, _leftovers|
    msg  = "Parsed results when 'missing argument' error was raised"
    msg << "\non option '#{err.option.name_full}'" if err.option
    puts "#{msg} => #{results.pretty_inspect}"
    !results[:e]
  end
end
