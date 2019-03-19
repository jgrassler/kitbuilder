#
# Download dependency from repo1.maven.org/maven2
#

module Kitbuilder
  class ApacheStaging < Repository
    def self.build_uri dependency
      uri = "https://repository.apache.org/content/groups/staging/" + dependency.group.split(".").join("/") + "/" + dependency.artifact
      if dependency.version
        uri += "/" + dependency.version
      end
      uri
    end
  end
end
