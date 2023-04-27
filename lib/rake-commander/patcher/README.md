# Patching `rake`

## Patch Rational

Let's say that when we invoke `rake` from the command line, `rake-commander` is loaded from a `Rakefile` (i.e. `require 'rake-commander'`). Looking at the `Rake::Application#run` method code, this places the patch moment, at the best, during the load of the `Rakefile`; during execution of the `load_rakefile` private method ([here is the call](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L82)).

### Challenges encountered with the `rake` executable

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

### The alternative of a `raked` executable

**`raked` executable is not necessary and is not provided for prod environments. The current patch allows to start directly from `rake`**.

  * This has been kept to the only purpose of documentation.

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


## Reload `Rake` application

The target is to be able to use `rake` indistinctly (rather than having to rewrite rake commands as `raked`). Unfortunately the **only way around** to the _application-has-started_ is to just **relaunch/reload the application** when the patch kicks in (wouldn't know how to and shouldn't try to reuse the current running application: i.e. task options parsed as rake option modifiers that have already done some stuff).

Fortunately, the target of `rake-commander` is just to **enhance** existing syntax, which gives a very specific target when it comes to **patching**. The key factor to reach a clean patch is to design the syntax in a fixed way where there is no much flexibility but clearly stated delimiters (i.e. no fancy guessing where dependencies are introduced on defined task options).

Relaunching the application to a new instance requires very little:

```ruby
Rake.application = Rake::Application.new
Rake.application.run
exit(0) # abort previous application run
```

## Missing tasks on reload

Relaunching the `rake` application entails issues with `require` in the chain of `Rakefile` files that have already been loaded. Apparently some tasks of some gems are installed during the `require` runtime, rather than explicitly declaring them in the rake file.

This is the case for `bundler/gem_tasks` (i.e. `require "bundler/gem_tasks"`), where all these `tasks` will be missing: build, build:checksum, clean, clobber, install, install:local, release, release:guard_clean, release:rubygem_push, release:source_control_push.

It can potentially be looked at, if ever this shows up to new review.
