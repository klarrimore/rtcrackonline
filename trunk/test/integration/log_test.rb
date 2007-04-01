#!/usr/bin/ruby -w

require 'socket'
require 'logger'

require File.dirname(__FILE__) + '/../../config/boot'
ENV["RAILS_ENV"] = 'development'
require RAILS_ROOT + '/config/environment'

logger = RAILS_DEFAULT_LOGGER

logger.info "THIS THING WORKS"
