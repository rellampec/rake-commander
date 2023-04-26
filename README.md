# RakeCommander

Another way to define re-usable rake tasks and samples.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rake-commander', require: %w[rake-commander]
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rake-commander

## Syntax

See **Usage** section.

### Command Line

Although it is planned to extend the syntax, the current version allows to pass **options only to one task**.

```
rake [rake-options] task1 task2 -- [task1-options]
```

The method is to divide `ARGV` into two parts based on the first space-surrounded double dash ` -- `.

```
<rake part> -- [task1 options part]
```

#### Fix pending

Tasks declared using `RakeCommander` are getting `argv` uncut, which includes the task as an argument.

```
$ rake examples:chainer
rake aborted!
RakeCommander::Options::Error::UnknownArgument: (examples:chainer) unknown arguments: 'examples:chainer'
```

Annoyingly, this requires to call them with double dash at the end `--`

```
rake examples:chainer --
Nothing to do :|
```

### `raked` executable

`raked` is a modified version of the `rake` executable, where `Rake` is **slightly patched** (by rake commander) before `Rake::Application.run` is invoked. This allows to modify the `ARGV` parsing behaviour of `rake`, giving room for **opinionated enhanced syntax**.

### `rake` full support

Work has been done with the aim of providing a full patch on `rake`, provided that the main invocation command remains as `rake` (rather than `raked`).

To preserve `rake` as invocation command, though, the patch re-launches the rake application when it has already initialized. The reason is that `rake` has already pre-parsed `ARGV` when `rake-commander` is loaded (i.e. from a `Rakefile`).

  * For compatibility with tasks declared using `RakeCommander`, it has been discarded a conditional rake application launch based on the presence of enriched syntax (i.e. the presence of `--` delimiter as an argument).
  * For this to be possible, would need to check on tasks identified by rake at the point of the 2nd patch (on `Rake::Application#top_level`) and figure out if any of those tasks was declared via `RakeCommander` and requires the patch to be active (relaunch rake application). Although should not be hard to keep track on all the tasks declared via `RakeCommander`, this would need further thoughts on possible drawbacks.

### Options Syntax & Parsing

It supports most of options syntax of the native `OptionParser` but for a couple of exceptions perhaps:
  1. It does **NOT** support definitions or parsing of shortcuts with **embedded argument** (i.e. `-nNAME`).
  2. It does **NOT** support definitions that include equal sign (i.e. `name=NAME`, `n=NAME`)

An argument should be explicitly declared in the `name` part:

```
  option :n, '--name NAME'
```

## Usage

See the `examples`. You can run them with `raked` (`bin/raked` in _development_), which is just like `rake` executable with the difference that it loads `RakeCommander` right after `Rake` is loaded and before `Rake::Application.run` is invoked.

```
raked examples:basic -- -h
raked examples:basic -- -z -e prod
```
  * The double dash `--` is used to tell to rake-commander where the options section starts.

The `Rakefile` has three lines that can serve as a guide. One were we require `rake-commander`, another where we define our `RakeCommander` classes, and one where we load them as actual `Rake` tasks.

```ruby
require_relative 'lib/rake-commander'
Dir["examples/*_example.rb"].each {|file| require_relative file }
RakeCommander.self_load
```

### Problems of using `rake` executable

Let's say you require/load `rake-commander` in a `Rakefile`, and invoke the [`rake` executable](https://github.com/ruby/rake/blob/master/exe/rake). By the time rake commander is loaded, `Rake` has already captured the `ARGV`, parsed its own options, and pre-parsed possible task(s) invokations.

The **two main problems** to deal with are:

  1. Rake has it's own `OptionsParser`. If any of your rake `task` options matches any of those, you will be unintentionally invoking `rake` functionality.
  2. Let's say you require/load `rake-commander` in a `Rakefile`. By the time rake commander is loaded, `rake` has already collected as `top_level_tasks` the arguments of your task options; so those that do not start with dash `-` ([see private method `collect_command_line_tasks` in `Rake::Application`](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L782)).

This is also true when you invoke `rake` via _shell_ from within another task.

**Example**

Without the current patch, this is what was happening.

```
$ bin\raked examples:chainer -- --chain --say "Just saying..." --with raked
Calling --> 'rake examples:chained -- --say "Just saying..."'
Chained task has been called!!
Just saying...
rake aborted!
Don't know how to build task 'Just saying...' (See the list of available tasks with `rake --tasks`)
```

#### Alternative with `raked` executable

**`raked` executable is not necessary. The current patch allows to start directly from `rake`**.

For this reason the `raked` executable was thought to be provided by this gem. The same example above, whe ran with `raked`, would show just perfectly work (as the patch was active when rake application would parse `ARGV`):

```
$ bin\raked examples:chainer -- --chain --say "Just saying..." --with raked
Calling --> 'bin\raked examples:chained -- --say "Just saying..."'
Chained task has been called!!
Just saying...
```

### Patching `Rake`

Rake commander does come with a neat patch to the [`Rake::Application#run` method](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L79) to clean up the `ARGV` before the rake application starts. But it kicks in too late...

For this reason a more arguable patch has been applied to [`Rake::Application#top_level` method](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L131)

#### Patch Rational

Let's say that when we invoke `rake` from the command line, `rake-commander` is loaded from a `Rakefile` (i.e. `require 'rake-commander'`). Looking at the `Rake::Application#run` method code, this places the patch moment, at the best, during the load of the `Rakefile`; during execution of the `load_rakefile` private method ([here is the call](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L82)).

Some parsed options are being used at this stage (see [`raw_load_rakefile`](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L719)). As commented before, it can happen that `rake` parsed some of the options that target a `task` rather than just the options that target the `rake` application (which is clearly undesired).

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
