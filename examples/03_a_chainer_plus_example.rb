class RakeCommander::Custom::ChainerPlus < RakeCommander::Custom::Chainer
  TARGET_TASK = 'examples:chained_plus'

  desc "Uses rake (or raked) to invoke #{TARGET_TASK}"
  task :chainer_plus

  # Update option description
  option_reopen :chain, desc: "Calls: '< rake|raked > #{TARGET_TASK} task'"
  # Extend with new option
  option :o, '--hello NAME', String, desc: 'It greets.'

  def task(*_args)
    puts "Hello #{options[:o]}!!" if options[:o]
    super
  end
end
