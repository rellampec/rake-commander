class RakeCommander::Custom::Chainer < RakeCommander
  namespace :examples

  desc 'A task that uses rake or raked to invoke another task'
  task :chainer

  option :c, :chain, TrueClass, desc: "Calls: '< rake|raked > examples:chained task'"
  option :w, '--with CALLER', default: 'raked', desc: "Specifies if should invoke with 'rake' or 'raked'"
  option '-s', '--say [SOMETHING]', "It makes chainer say 'something'"

  def task(*_args)
    if options[:c]
      with = options[:w] == 'rake' ? 'rake' : 'bin\raked'
      cmd  = "#{with} examples:chained"
      cmd << " -- --say \"#{options[:s]}\"" if options[:s]
      
      puts "Calling --> '#{cmd}'"
      system(cmd)
    else
      puts "Nothing to do :|"
    end
  end
end
