require 'rake'
require_relative 'rake-commander/base'

class RakeCommander
  include RakeCommander::Base
end

require_relative 'rake-commander/version'
require_relative 'rake-commander/custom'
