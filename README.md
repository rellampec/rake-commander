# RakeCommander

Classing rake tasks with options. Creating re-usable tasks, options and samples thereof.

## Introduction

Rake commander is a way to declare **rake tasks** with re-usable classes. It enhances the command line syntax, as tasks can come with their own **options**, inherit them, re-use declared options sets, modify/re-open or even remove them.

Although the `OptionParser` ruby native class is used for parsing the options, the declaration of options, additionally to the ones of `OptionParser` comes with some **opinionated improvements** and amendments:

1. It is possible to declare options as `required`
   * This is additional to required option arguments.
   * Options are inheritable (they get a custom `deep_dup`)
1. An option can have a `default` value.
   * Which can optionally be automatically used when the option accepts or requires an argument.
1. Options parsing raises specific option errors. For a given task/class, each error type can have its own handler or preferred action.
   * Defined error handling is inheritable and can be redefined.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rake-commander', require: %w[rake-commander]
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rake-commander

## Usage

See [**the `examples`**](https://github.com/rellampec/rake-commander/tree/main/examples).

```
rake -T examples
```

Go through the [basic example](https://github.com/rellampec/rake-commander/blob/main/examples/01_basic_example.rb).

```
rake examples:basic -- -h
rake examples:basic -- -z -e prod
```
  * The double dash `--` is used to tell to rake-commander where the options section starts.

At the same time the double dash delimiter seems to make rake ignore anything that comes afterwards. Without loading rake commander, you could try:

```
$ rake --trace rspec
** Invoke spec (first_time)
** Execute spec
rspec logging and results
```

And then re-try with

```
$ rake rspec -- --trace
rspec logging and results
```

  * The `--trace` option is being natively ignored by `rake` due to the preceding double dash (` -- `).


### Syntax

```ruby
RakeCommander::Custom::Base < RakeCommander
  include Rake::DSL
end
```
  * `include Rake::DSL` for backwards compatibility

```ruby
RakeCommander::Custom::MyTask < RakeCommander::Custom::Base
  desc "it does some stuff"
  task :do_stuff

  option :s, '--do-stuff [SOMETHING]', default: 'nothing'

  def task(*_args)
    puts "Doing #{options[:s]}" if options[:s]
  end
end
```


### Declaring and using Task Options

It supports most of options syntax of the native `OptionParser` but for a couple of exceptions perhaps:
  1. It does **NOT** support definitions or parsing of shortcuts with **embedded argument** (i.e. `-nNAME`).
  2. It does **NOT** support definitions that include equal sign (i.e. `name=NAME`, `n=NAME`)
  3. Currently, declaring a short and a name for the option is compulsory.

An argument of an option should be explicitly declared in the `name` part:

```ruby
  option :n, '--name NAME'
```

### Command Line

Although it is planned to extend the syntax, the current version shares the options through all tasks (declared as `RakeCommander` classes) that are invoked in the same command line.

```
rake [rake-options] task1 task2 -- [shared-task-options]
```

The double dash ` -- ` delimiter allows to modify the `ARGV` parsing behaviour of `rake`, giving room for **opinionated enhanced syntax**. Anything that comes before the double dash is fed to standard `rake`, and anything after `--` are parsed as option tasks via `rake commander`.

```
<rake part> -- [tasks options part]
```

## `rake` full support

Work has been done with the aim of providing a full patch on `rake`, provided that the main invocation command remains as `rake`.

To preserve `rake` as invocation command, though, the patch needs to relaunch the rake application when it has already started. The reason is that `rake` has already pre-parsed `ARGV` when `rake-commander` is loaded (i.e. from a `Rakefile`) and has identified as tasks things that are part of the task options.

  * For compatibility with tasks declared using `RakeCommander`, the rake application is always relaunched. Anything that does not belong to task options should not be feed to rake tasks declared with rake commander classes.

### Patching `Rake`

The two patches:

  1. Rake commander does come with a neat patch to the [`Rake::Application#run` method](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L79) to clean up the `ARGV` before the rake application starts. But it kicks in too late...
  2. For this reason a more arguable patch has been applied to [`Rake::Application#top_level` method](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L131), where the rake application is relaunched.

For further details please see [`RakeCommander::Patcher`](https://github.com/rellampec/rake-commander/blob/main/lib/rake-commander/patcher).


## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

For more info on available `Rake` tasks: `rake -T` (or `bin/raked -T`)
