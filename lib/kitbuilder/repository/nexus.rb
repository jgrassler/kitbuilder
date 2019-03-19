#
# Download dependency from repo1.maven.org/maven2
#

module Kitbuilder
  class Nexus < Repository
    def self.build_uri dependency
      uri = "https://app.camunda.com/nexus/content/repositories/public/" + dependency.group.split(".").join("/") + "/" + dependency.artifact
      if dependency.version
        uri += "/" + dependency.version
      end
      uri
    end
  end
end
