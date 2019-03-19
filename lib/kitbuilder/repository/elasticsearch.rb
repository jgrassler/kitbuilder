#
# Download dependency from repo1.maven.org/maven2
#

module Kitbuilder
  class Elasticsearch < Repository
    def self.build_uri dependency
      uri = "http://maven.elasticsearch.org/releases" + dependency.group.split(".").join("/") + "/" + dependency.artifact
      if dependency.version
        uri += "/" + dependency.version
      end
      uri
    end
  end
end
