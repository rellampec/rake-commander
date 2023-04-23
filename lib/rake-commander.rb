require 'rake'
require_relative 'rake-commander/base'
require_relative 'rake-commander/patcher'

class RakeCommander
  include RakeCommander::Base
  include RakeCommander::Patcher
end

require_relative 'rake-commander/version'
require_relative 'rake-commander/custom'
