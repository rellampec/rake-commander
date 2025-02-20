# Change Log

All notable changes to this project will be documented in this file.

## TO DO

- Think if [`binstubs`](https://github.com/rbenv/rbenv/wiki/Understanding-binstubs) would offer a neater patch right on `Rake::Application#init`
- `option_reopen` -> upsert should be optional (add `upsert: false` as default an raise missing option if not found)
  - The error on missing short pops up where it's not clear the short was missed in the option_reopen call.
- Option results
  - Include the symbol name keys (configurable). Note that dash will be replaced by underscore.
- Type Coercions
  - Add a way to define/redefine a set and use them.
  - Add more supported type_coercions as native to the gem (i.e. `Symbol`)
  - Add support [for `ActiveRecord::Enum`](https://apidock.com/rails/ActiveRecord/Enum)
- Option definitions
  - Order: `where: [:tail, :top]` and `[after, before]: :option_name`
  - Configuration: allow to define option override behaviour and whether it should trigger an exception
- Error handlers
  - See if it would be possible to parse all the valid options so we get all the valid results before some error is raised. Although this can be achieved with `OptionParser#order!`, it destroys switches; which would require to give it two parsing shots whenever there is an error.
    - It should be ensured that the parsed options results object is remains the same.
    - Think about options that modify other options. Technically this should be hold only at behaviour level
  - This would allow to make the order of the options irrelevant when it comes to modify error handling behaviour via options themselves.
- Rake task parameters (see: <https://stackoverflow.com/a/825832/4352306> & <https://stackoverflow.com/a/825832/4352306>)
- Add `enhance` functionality (when a task is invoked it runs before it; declared with `task` as well)
- Add `no_short` option (which should give the result of that option with the option name key)
- Add `on_option` handler at instance level, so within a `task` definition, we can decide certain things, such as if the functionality should be active when the `self.class` does not have that option.
  - This is specially useful to be able to extend through inheritance chain, where we extend `task` (rather than redefining it), but we don't want options we removed (with `option_remove`) to throw unexpected results.
  - Example: `on_option(:t, defined: true) {|option| do-stuff}` <- block to be called only if the option is defined in the class (alternative: `defined: :only`)
  - Example: `on_option(:t, defined: false) {|option| do-stuff}` <- block to be called regardless the option exists (alternative: `defined: :ignore`)
  - Example: `on_options(:t, :s, present: true) {|options| do-stuff}` <- block to be called only when the option `:t` and `:s` are both present in the parsed `options` result.
  - Once this has been done,  think about it being a hash-alike object with methods for the option names (i.e. `options.debug?`)

## [0.4.1] - 2025-02-xx

### Added

- Predefined values cohertion (i.e. `Enum`)

### Fixed

- Description: break lines should be respected.

### Changed

- Allow multiple `desc` declarations to be aligned with `OptsParser` behaviour.

## [0.4.0] - 2023-08-01

### Changed

- require `ruby 3`

## [0.3.6] - 2023-05-15

### Fixed

- `RakeCommander::Options` inheritance of options in `options_hash` was NOT doing a `dup`

### Changed

- `RakeCommander::Options#options_hash` made public method

## [0.3.5] - 2023-05-08

### Fixed

- `RakeCommander::Options#option_reopen` using name to reopen should not redefine if passed as Symbol.

## [0.3.4] - 2023-05-08

### Fixed

- `RakeCommand::Option#name` boolean form (`[no-]`) should not be part of the name.

### Changed

- Slight refactor to the patch

## [0.3.3] - 2023-05-01

### Changed

- Replaced the patching method, so the `Rake` application doesn't need re-launch.

## [0.2.12] - 2023-05-01

### Fixed

- `RakeCommander::Option#type_coercion` wasn't correctly captured.

## [0.2.11] - 2023-05-01

### Fixed

- When `RakeCommander::Option#type_coercion` is `FalseClass`, it should reverse the result.

## [0.2.10] - 2023-05-01

### Fixed

- `RakeCommander::Options` clean `options_hash` inheritance.

## [0.2.7] - 2023-05-01

### Fixed

- `RakeCommander::Option#desc` when fetching from other, should not fetch array but single value.

## [0.2.6] - 2023-05-01

### Changed

- `RakeCommander::Option` configure_other should only apply when the instance vars are not defined.

## [0.2.5] - 2023-05-01

### Changed

- `RakeCommander::Base::ClassInheritable#inherited_class_value` now expects a reference to the subclass

## [0.2.4] - 2023-04-30

### Added

- `RakeCommander::Options`
  - `::option_get` retrieves an option by name or short, may it exist.
  - `::option?` to check if an opion exists.

## [0.2.3] - 2023-04-29

### Added

- Include Symbol option names in the parsed option results.

## [0.2.2] - 2023-04-29

### Fixed

- Typo in `RakeCommander::Base::ClassAutoLoader`

## [0.2.1] - 2023-04-29

### Fixed

- `RakeCommander::Option` type coercion was not being inherited
- Typo on `coertion`: writes `coercion`

## [0.2.0] - 2023-04-28

### Added

- Better support for `RakeCommander::Options::Set`
  - `RakeCommander::Options::options_use` accepts it as a parameter.
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
- `RakeCommander::Options::Error::Handling` which provides **configurability** around actions on specific option errors with a default to a general options parsing error.

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
