# Change Log
All notable changes to this project will be documented in this file.

## TO DO
  - Rake task parameters (see: https://stackoverflow.com/a/825832/4352306)
  - Invoke `rake-dash` from `rake` (can't override `rake` executable; Rake gem update will override it)

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

### Fixed
  - `RakeCommander::Base::ClassAutoLoader`
    - Register excluded child classes (singleton classes) into their own property,
      rather than in the `autoloaded_children` (they are not autoloaded).
  - Missing `rake` dependency in gemspec file.
  - Boolean switch detection (pre-parse arguments) and parsing
    - It adds support for boolean option names such as `--[no-]verbose`
  - Error messaging. There were missing cases, specially with implicit short options.

### Changed
  - Development: examples invokation via `Rake`
  - Refactored `RakeCommander::Options` to acquire functionality through extension.

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
