# Patching `rake`

## Patch Rational

Let's say that when we invoke `rake` from the command line, `rake-commander` is loaded from a `Rakefile` (i.e. `require 'rake-commander'`). Looking at the `Rake::Application#run` method code, this places the patch moment, at the best, during the load of the `Rakefile`; during execution of the `load_rakefile` private method ([here is the call](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L82)).

### Challenges encountered with the `rake` executable

Let's say you require/load `rake-commander` in a `Rakefile`, and invoke the [`rake` executable](https://github.com/ruby/rake/blob/master/exe/rake). By the time rake commander is loaded, `Rake` has already captured the `ARGV`, parsed its own options, and pre-parsed possible task(s) invokations; it has already collected as `top_level_tasks` the arguments of your task options; so those that do not start with dash `-` ([see private method `collect_command_line_tasks` in `Rake::Application`](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L782)).

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

## Reload `Rake` application

Relaunching the application to a new instance requires very little:

```ruby
Rake.application = Rake::Application.new
Rake.application.run
exit(0) # abort previous application run
```
But this approach has been discarded (since `v 0.3.1`), as it loses task definitions loaded via `require`.

### Missing tasks on reload

Relaunching the `rake` application entails issues with `require` in the chain of `Rakefile` files that have already been loaded. Apparently some tasks of some gems are installed during the `require` runtime, rather than explicitly declaring them in the rake file.

This is the case for `bundler/gem_tasks` (i.e. `require "bundler/gem_tasks"`), where all these `tasks` will be missing: build, build:checksum, clean, clobber, install, install:local, release, release:guard_clean, release:rubygem_push, release:source_control_push.

## Re-call `collect_command_line_tasks` from `top_level` method

This showed up to solve all the known problems mentioned above. It allow the application to just keep running with whatever it got.
