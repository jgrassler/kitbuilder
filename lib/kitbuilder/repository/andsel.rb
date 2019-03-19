#
# Download dependency from repo1.maven.org/maven2
#

module Kitbuilder
  class Andsel < Repository
    def self.build_uri dependency
      uri = "http://dl.bintray.com/andsel/maven/" + dependency.group.split(".").join("/") + "/" + dependency.artifact
      if dependency.version
        uri += "/" + dependency.version
      end
      uri
    end
  end
end
