class RakeCommander::Custom::ChainerOptionsSet < RakeCommander::Options::Set
  name :chainer_options

  option :c, :chain, TrueClass, desc: "Calls: '< rake|raked > chained-task task'"
  option :w, '--with CALLER', default: 'rake', desc: "Specifies if should invoke with 'rake' or 'raked'"
  option '-s', "It makes the chained-task say 'something'", name: '--say [SOMETHING]'
  option '-b', '--debug', TrueClass, 'Whether to add additional context information to messages'
end
