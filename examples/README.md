## Examples

The `Rakefile` has three lines that can serve as a guide. One were we require `rake-commander`, another where we define our `RakeCommander` classes, and one where we load them as actual `Rake` tasks.

```ruby
require_relative 'lib/rake-commander'
#RakeCommander::Patcher.debug = true
Dir["examples/*_example.rb"].each {|file| require_relative file }
RakeCommander.self_load
```

  * The commented line is just to be able to see the patch in action (throws some console logs).

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
