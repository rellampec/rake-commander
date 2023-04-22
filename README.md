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

## Usage


### Options Syntax & Parsing

It supports most of options syntax of the native `OptionParser` but for one exception perhaps:
  1. It does not support definitions NOR parsing of shortcuts with embedded argument (i.e. `-nNAME`).

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

For more info on available `Rake` tasks: `rake -T`
