#
# Download dependency from repo1.maven.org/maven2
#

module Kitbuilder
  class SonatypeSnapshots < Repository
    def self.build_uri dependency
      uri = "https://oss.sonatype.org/content/repositories/snapshots/" + dependency.group.split(".").join("/") + "/" + dependency.artifact
      if dependency.version
        uri += "/" + dependency.version
      end
      uri
    end
  end
end
