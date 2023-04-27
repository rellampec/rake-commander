## Examples

  * `RakeCommander` is loaded from the repo branch you are checked out.

The Rakefile `Examples.rake` has three lines that can serve as a guide. One were we require `rake-commander`, another where we define our `RakeCommander` classes, and one where we load them as actual `Rake` tasks.

```ruby
require_relative '../lib/rake-commander'
RakeCommander::Patcher.debug = ENV['COMMANDER_DEBUG'] == "true"
Dir["#{__dir__}/*_example.rb"].sort.each {|file| require_relative file }
RakeCommander.self_load
```

  * To see the patches in action, you can add `COMMANDER_DEBUG=true` to a `.env` file

```
rake -T examples
```

### Basic Example

```
rake examples:basic -- -h
rake examples:basic -- -z -e prod
```

### Chainer && Chained Example

Two tasks where chainer calls chained through **a `shell` call to `rake`**.

  * Read well the example before running it.

```
rake examples:chainer -- -h
rake examples:chained -- -h
```

### Chainer Plus and Chained Plus Example

Same as the previous example but these tasks inherit from the previous example, extending their behaviour and changing the options.


```
rake examples:chainer_plus -- -h
rake examples:chained_plus -- -h
```

#### Error handling mixed with options

The option `--exit-on-error` allows the error handler defined in `chained_plus` to decide if it should raise the error or just do an `exit 1`

  * This is possible because the order that the options have been declared. Observe that they `--say` option has been removed and redefined **after** the option `--exit-on-error` has been defined.
  * `OptionParser` **switches are processed in order** and, therefore, the error on `--say` only pops up after the `--exit on-error` option has been already parsed.

While this will raise the error (with a trace):

```
$ rake examples:chainer_plus -- --chain --say
Calling --> 'rake examples:chained_plus -- --say'
Parsed results when 'missing argument' error was raised
on option '--say SOMETHING' => {}
rake aborted!
RakeCommander::Options::Error::MissingArgument: (examples:chained_plus) missing required argument in option: --say SOMETHING (-s)
< here back trace>
Tasks: TOP => examples:chained_plus
(See full trace by running task with --trace)
* Failed to running 'rake examples:chained_plus -- --say'
```

This will only print the error with an `exit 1`:

```
$  rake examples:chainer_plus -- --chain --say --exit-on-error
Calling --> 'rake examples:chained_plus -- --exit-on-error --say'
Parsed results when 'missing argument' error was raised
on option '--say SOMETHING' => {:e=>true}
(examples:chained_plus) missing required argument in option: --say SOMETHING (-s)
* Failed to running 'rake examples:chained_plus -- --exit-on-error --say'
```
