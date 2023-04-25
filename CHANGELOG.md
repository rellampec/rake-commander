# Change Log
All notable changes to this project will be documented in this file.

## TO DO
  - Option parsing Errors:
    * configuration: allow to optionally just print error message and do an `exit(1)` when there is an options error
      (`rake` just exits on OptionParser error)
  - Add more supported type_coertions (i.e. `Symbol`)
    - Add support [for `ActiveRecord::Enum`](https://apidock.com/rails/ActiveRecord/Enum)
  - Rake task parameters (see: https://stackoverflow.com/a/825832/4352306)
  - Add `enhance` functionality (when a task is invoked it runs before it; declared with `task` as well)
  - Add `no_short` option (which should give the result of that option with the option name key)

## DISCARDED IMPROVENTS
  - Option to globally enable/disable the 2nd patch?
    * That would make this gem completely useless.

## [0.2.1] - 2023-04-xx

### Added
### Fixed
### Changed


## [0.2.0] - 2023-04-23

### Added
  - Better support for `RakeCommander::Options::Set`
    - `RakeCommander::Options::use_options` accepts it as a parameter.
    - Added `override` parameter to specify if this should override clashed option names.
  - `RakeCommander::Options::class_resolver` to define the `RakeCommander::Option` class.
    - Serves the purpose to ease class extension through inheritance.
  - Ability to reopen options without changing the order.
    - `RakeCommander::Options::option_reopen` which upserts (adds if not existing).
    - New parameter `reopen` to `RakeCommander::Options::option` (redirects to the above method).
  - Automatic option shortcuts (`implicit_shorts`) show in help and only when applicable.
    - These are added automatically by `OptionParser`
  - `OptionParser` leftovers trigger an error by default.
    - This behaviour can be disabled or modified via callback/block by using `RakeCommander::Options:Error::error_on_leftovers`.
  - Description auto **multi-line**
    - Currently based on `RakeCommander::Options::Description::DESC_MAX_LENGTH`
  - `RakeCommander::Options#remove_option`
  - `RakeCommander::Options::Error::Base` and children can be raised using different methods (see `RakeCommander::Options::Error` for examples).
    - The **task** `name` that raised the error is included in the message.

### Fixed
  - `RakeCommander::Base::ClassAutoLoader`
    - Register excluded child classes (singleton classes) into their own property,
      rather than in the `autoloaded_children` (they are not autoloaded).
  - Missing `rake` dependency in gemspec file.
  - Boolean switch detection (pre-parse arguments) and parsing
    - It adds support for boolean option names such as `--[no-]verbose`
  - Error messaging. There were missing cases, specially with implicit short options.
  - `RakeCommander::Options`
    - `#option_reopen` fixed
    - **Inheritance fixed**

### Changed
  - Development: examples invokation via `Rake`
  - Refactored `RakeCommander::Options` to acquire functionality through extension.
  - `attr_inheritable` and `inheritable_class_var` are the new names of previous methods
    - Behaviour has been changed, so you define if it should `dup` the variables, and you can pass a `block` to do the `dup` yourself. They won **NOT** `freeze` anymore, as we are mostly working at class level.

## [0.1.4] - 2023-04-20

### Fixed
  - `rubocop` offenders
  - Added implicity `exit(0)` when wrapping the `task` block

## [0.1.3] - 2023-04-20

### Fixed
  - Reference to repo and gem

## [0.1.2] - 2023-04-19

### Added
  - First commit
