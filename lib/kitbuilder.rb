#--
# Copyright (c) 2016 SUSE LINUX Products GmbH
#
# Author: Klaus Kämpf <kkaempf@suse.de>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
require 'rubygems'
require 'kitbuilder/version'
require 'kitbuilder/pom'
require 'kitbuilder/dependency'
require 'kitbuilder/download'
require 'kitbuilder/maven2'
require 'kitbuilder/bintray'
require 'kitbuilder/gradle'
require 'kitbuilder/sonatype'
require 'kitbuilder/torquebox'

module Kitbuilder

  class Kitbuilder
    def initialize m2dir = nil
      @m2dir = m2dir
      Pom.destination = @m2dir
    end
    # specify .jar to download
    def jar= j
      @jar = j
    end
    def handle pomspec
#      puts "Handle #{pomspec.inspect}"
      pom = Pom.new pomspec
      pom.jar = @jar
      pom.resolve
    end
  end

end
