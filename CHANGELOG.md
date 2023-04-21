# Change Log
All notable changes to this project will be documented in this file.

## TO DO
  - Specify what options are REQUIRED in help lines.
  - Rake task parameters (see: https://stackoverflow.com/a/825832/4352306)
  - `OptionParser#parse` result (what to do with unknown ARGV `leftovers`)

## [0.1.5] - 2023-04-xx

### Added
  - Better support for `RakeCommander::Options::Set`
    - `RakeCommander::Options::use_options` accepts it as a parameter.
    - Added `override` parameter to specify if this should override clashed option names.

### Fixed
  - `RakeCommander::Base::ClassAutoLoader`
    - Register excluded child classes (singleton classes) into their own property,
      rather than in the `autoloaded_children` (they are not autoloaded).
  - Missing `rake` dependency in gemspec file.

### Changed

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
