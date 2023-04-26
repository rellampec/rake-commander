# RakeCommander

Another way to define re-usable rake tasks and samples.

## Introduction

Rake commander is a way to declare **rake tasks** with re-usable classes. It enhances the command line syntax, as tasks can come with their own **options**, inherit them, re-use declared options sets, modify/re-open or even remove them.

Although the `OptionParser` ruby native class is used for parsing the options, the declaration of options, additionally to the ones of `OptionParser` comes with some **opinionated improvements** and amendments:

1. It is possible to declare options as `required`
  * This is additional to required option arguments.
  * Options are inheritable (they get a custom `deep_dup`)
2. An option can have a `default` value.
  * Which can optionally be automatically used when the option accepts or requires an argument.
3. Options parsing raises specific option errors. For a given task/class, each error type can have its own handler or preferred action.
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

### Declaring and using Task Options

It supports most of options syntax of the native `OptionParser` but for a couple of exceptions perhaps:
  1. It does **NOT** support definitions or parsing of shortcuts with **embedded argument** (i.e. `-nNAME`).
  2. It does **NOT** support definitions that include equal sign (i.e. `name=NAME`, `n=NAME`)

An argument should be explicitly declared in the `name` part:

```
  option :n, '--name NAME'
```

### Command Line

Although it is planned to extend the syntax, the current version shares the options through all tasks (declared as `RakeCommander` classes) that are invoked in the same command line.

```
rake [rake-options] task1 task2 -- [shared-task-options]
```

The double dash ` -- ` delimiter allows to modify the `ARGV` parsing behaviour of `rake`, giving room for **opinionated enhanced syntax**. Anything that comes before the double dash is feed to standard `rake`, and anything after `--` are parsed as option tasks via `rake commander`.

```
<rake part> -- [tasks options part]
```

### `rake` full support

Work has been done with the aim of providing a full patch on `rake`, provided that the main invocation command remains as `rake`.

To preserve `rake` as invocation command, though, the patch needs to relaunch the rake application when it has already started. The reason is that `rake` has already pre-parsed `ARGV` when `rake-commander` is loaded (i.e. from a `Rakefile`) and has identified as tasks things that are part of the task options.

  * For compatibility with tasks declared using `RakeCommander`, the rake application is always relaunched. Anything that does not belong to task options should not be feed to rake tasks declared with rake commander classes.

#### Challenges encountered with the `rake` executable

Let's say you require/load `rake-commander` in a `Rakefile`, and invoke the [`rake` executable](https://github.com/ruby/rake/blob/master/exe/rake). By the time rake commander is loaded, `Rake` has already captured the `ARGV`, parsed its own options, and pre-parsed possible task(s) invokations.

The **two main problems** to deal with are:

  1. Rake has it's own `OptionsParser`. If any of your rake `task` options matches any of those, you will be unintentionally invoking `rake` functionality.
  2. Let's say you require/load `rake-commander` in a `Rakefile`. By the time rake commander is loaded, `rake` has already collected as `top_level_tasks` the arguments of your task options; so those that do not start with dash `-` ([see private method `collect_command_line_tasks` in `Rake::Application`](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L782)).

This is also true when you invoke `rake` via _shell_ from within another task.

**Example**

Without the current patch, this is what was happening.

```
$ raked examples:chainer -- --chain --say "Just saying..." --with raked
Calling --> 'rake examples:chained -- --say "Just saying..."'
Chained task has been called!!
Just saying...
rake aborted!
Don't know how to build task 'Just saying...' (See the list of available tasks with `rake --tasks`)
```

#### The alternative of a `raked` executable

**`raked` executable is not necessary. The current patch allows to start directly from `rake`**.

  * This has been kept to the only purpose documentation.

The `raked` executable would be a modified version of the `rake` executable, where `rake_commander` is loaded right after requiring `rake` and before `Rake.application.run` is invoked.

```ruby
#!/usr/bin/env ruby

require "rake"
require "rake-commander"
Rake.application.run
```

This would allow the patch to be active right at the beginning, preventing this way the patch to kick in after the `rake` application has been firstly launched (it saves to rake one loop of parsing arguments and loading rake files).

```
$ raked examples:chainer -- --chain --say "Just saying..." --with raked
Calling --> 'bin\raked examples:chained -- --say "Just saying..."'
Chained task has been called!!
Just saying...
```

Using `raked` as separate namespace vs `rake` is completely optional. Most will prefer to keep on just with the main `rake` executable and  `rake-commander` as enhancement to it. This is the rational behind the second patch (explained in detail in the next section).

### Patching `Rake`

The two patches:

  1. Rake commander does come with a neat patch to the [`Rake::Application#run` method](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L79) to clean up the `ARGV` before the rake application starts. But it kicks in too late...
  2. For this reason a more arguable patch has been applied to [`Rake::Application#top_level` method](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L131), where the rake application is relaunched.

#### Patch Rational

Let's say that when we invoke `rake` from the command line, `rake-commander` is loaded from a `Rakefile` (i.e. `require 'rake-commander'`). Looking at the `Rake::Application#run` method code, this places the patch moment, at the best, during the load of the `Rakefile`; during execution of the `load_rakefile` private method ([here is the call](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L82)).


#### Reload `Rake` application

The target is to be able to use `rake` indistinctly (rather than having to rewrite rake commands as `raked`). Unfortunately the **only way around** to the _application-has-started_ is to just **relaunch/reload the application** when the patch kicks in (wouldn't know how to and shouldn't try to reuse the current running application: i.e. task options parsed as rake option modifiers that have already done some stuff).

Fortunately, the target of `rake-commander` is just to **enhance** existing syntax, which gives a very specific target when it comes to **patching**. The key factor to reach a clean patch is to design the syntax in a fixed way where there is no much flexibility but clearly stated delimiters (i.e. no fancy guessing where dependencies are introduced on defined task options).

Relaunching the application to a new instance requires very little:

```ruby
Rake.application = Rake::Application.new
Rake.application.run
exit(0) # abort previous application run
```

#### Missing tasks on reload

Relaunching the `rake` application entails issues with `require` in the chain of `Rakefile` files that have already been loaded. Apparently some tasks of some gems are installed during the `require` runtime, rather than explicitly declaring them in the rake file.

This is the case for `bundler/gem_tasks` (i.e. `require "bundler/gem_tasks"`), where all these `tasks` will be missing: build, build:checksum, clean, clobber, install, install:local, release, release:guard_clean, release:rubygem_push, release:source_control_push.

It can potentially be looked at, if ever this shows up to new review.

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

For more info on available `Rake` tasks: `rake -T` (or `bin/raked -T`)
