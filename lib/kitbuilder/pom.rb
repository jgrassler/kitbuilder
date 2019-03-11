require 'nokogiri'

module Kitbuilder
  class Pom
    attr_reader :file, :group, :artifact, :scopes, :version, :parent, :with_sources, :verbose

    MAPPING = {
      "xerces-impl" => "xercesImpl",
      "jsr94-sigtest" => "jsr94"
    }
    
    EXTENSIONS = [
      ".pom", ".jar", ".pom.sha1", ".jar.sha1",
      ".zip", ".signature"
    ]
    def extensions
      EXTENSIONS
    end

    RELEVANT_MAPPING = {
      jar: ".jar", jarsha1: ".jar.sha1",
      pom: ".pom", pomsha1: ".pom.sha1",
      src: "-sources.jar",
      test: "-test.jar",
      tests: "-tests.jar",
      javadoc: "-javadoc.jar",
      runtime: "-runtime.jar",
      source_release: "-source-release.zip",
      signature: ".signature",
      noaop: "-noaop.jar",
      zip: ".zip",
      ns_resources: "-ns-resources.zip"
    }

    def relevant_mapping
      h = Hash.new
      @scopes.map { |s|
	      h.merge!({s.to_sym => s})
      }
      RELEVANT_MAPPING.merge(h)
    end

    # WGETS
    # keys of RELEVANT_MAPPING I want to wget
    WGETS = [:jar, :jarsha1,
      :pom, :pomsha1,
      :zip,
      :ns_resources,
      :signature,
      :noaop
    ]
    
    def wgets
      WGETS + @scopes.map{|s| s.to_sym}
    end
    #
    # set download directory
    #
    def self.destination= m2dir
      @@m2dir = m2dir
    end
    # getter
    def self.destination
      @@m2dir
    end

    #
    # find in maven universe
    #
    #  returns pomfile, jarfile, sourcesfile
    def find
      Maven2.find(self) || Central.find(self) || JCenter.find(self) || Bintray.find(self) || Gradle.find(self) || GradleReleases.find(self) || GradleLocal.find(self) || Torquebox.find(self) || JBoss.find(self) || GeoMajas.find(self)
    end
    #
    # download pom from maven universe
    #  returns cached, pomfile, sourcesfile
    def download
      Maven2.download(self) || Central.download(self) || JCenter.download(self) || Bintray.download(self) || Gradle.download(self) || GradleReleases.download(self) || GradleLocal.download(self) || Torquebox.download(self) || JBoss.download(self) || GeoMajas.download(self)
    end
    #
    #
    # download pom/jar
    #
    # @return full path to .pom file
    #
    def download_to path, with_sources = nil
      if @group[0,1] == "$"
        puts "\tCan't resolve group #{@group.inspect}"
        return
      end
      @with_sources = with_sources
      join = cached = sourcesfile = nil
      Dir.chdir @@m2dir do
        FileUtils.mkdir_p path
        Dir.chdir path do
          cached, pomfile, sourcesfile = self.download
          case pomfile
          when ::String
            join = File.join(@@m2dir, path, pomfile)
            # can't expand_path here !
          else
            return nil
          end
        end
      end
      [cached, File.expand_path(join), sourcesfile]
    end
    #
    # parse a .pom file
    #
    def parse file
      begin
        File.open(file) do |f|
          begin
            @xml = Nokogiri::XML(f).root
            namespaces = @xml.namespaces
            @xmlns = (namespaces["xmlns"])?"xmlns:":""
          rescue Exception => e
            STDERR.puts "Error parsing pom #{file}: #{e}"
            raise
          end
        end
      rescue Exception => e
        STDERR.puts "Error reading pom #{file}: #{e}"
        raise
      end
    end

    def parent= parent
      @parent = parent
    end
    def jar= jar
      @jar = jar
    end
    #
    # Pom representation
    #
    def initialize pomspec, verbose = nil
      @verbose = verbose
      artifact = nil
      case pomspec
      when Pom
        @group = pomspec.group
        artifact = pomspec.artifact
        @version = pomspec.version
        @scopes = pomspec.scopes
        @optional = pomspec.optional
      when Hash
        @group = pomspec[:group]
        artifact = pomspec[:artifact]
        @version = pomspec[:version]
        @scopes = pomspec[:scopes]
        @optional = pomspec[:optional]
      when Array # dir, base
        dir, base = pomspec
        dirs = dir.split("/")
        @version = dirs.pop
        artifact = dirs.pop
        @group = dirs.join('.')
        bases = base.split("-")
        @scopes = []
        Dir.foreach(dir) do |entry|
#          puts entry.inspect
          # docbook-xsl-1.76.1-ns-resources.zip
          # <base>-<version>-<scopes>.<extensions>
          #        $1        $3       $4
          next if entry =~ /\.lastUpdated/
          next unless entry =~ /#{base}\-?([^\.]*)\.(.+)/
#          puts "found #{$1.inspect},#{$2.inspect} for #{entry.inspect}"
          [$1, $2].each do |scope|
            next if scope.empty?
            next if scope == "pom"
            next if scope =~ /sha1/
            @scopes << scope
          end
        end
        @scopes.uniq!
#        puts "Pom.new(#{pomspec.inspect}) -> #{@group}:#{artifact}:#{@version.inspect}:#{@scopes.inspect}"
      when /\.pom/ # File
        parse pomspec
        project = @xml.xpath("/#{@xmlns}project")
        @group = project.xpath("#{@xmlns}groupId")[0].text.strip rescue project.xpath("#{@xmlns}parent/#{@xmlns}groupId")[0].text.strip
        artifact = project.xpath("#{@xmlns}artifactId")[0].text.strip
        @version = project.xpath("#{@xmlns}version")[0].text.strip rescue project.xpath("#{@xmlns}parent/#{@xmlns}version")[0].text.strip
        @file = pomspec
      when /\.jar/ # File
        dirs = pomspec.to_s.split('/')
        dirs.pop # .jar file
        @version = dirs.pop
        artifact = dirs.pop
        @group = dirs.join('.')
#        puts "Pom.new(#{pomspec}) -> #{@group}:#{artifact}:#{@version}"
      when /:/
        specs = pomspec.to_s.split(':')
        @group = specs.shift
        artifact = specs.shift
        @version = specs.pop # version is always last
        @scopes = specs
        puts "@group #{@group.inspect}, artifact #{artifact.inspect}, @scopes  #{@scopes.inspect}, @version #{@version.inspect}"
      else
        STDERR.puts "Unrecognized pomspec >#{pomspec.inspect}<"
      end
      @artifact = MAPPING[artifact] || artifact
    end
    #
    # Compare
    #
    def <=> other
      ret = @group <=> other.group
      if ret == 0
        ret = @artifact <=> other.artifact
        if ret == 0
          ret = @version <=> other.version
        end
      end
      ret
    end
    #
    # scope accessors
    #
    def test?
      @scopes.include? "test"
    end
    def runtime?
      @scopes.include? "runtime"
    end
    def compile?
      @scopes.include? "compile"
    end
    def zip?
      @scopes.include? "zip"
    end
    #
    # String representation
    #
    def to_s
      s = "#{@group}:#{@artifact}" + (@version?":#{@version}":"")
      if @optional||@scopes
        s += "<"
        s += "opt:" if @optional
        s += @scopes.join(",") if @scopes
        s += ">"
      end
      if @parent
        s += " < #{@parent}"
      end
      s
    end
    #
    # basename of .pom or .jar file
    #
    def basename
      basename = "#{@artifact}" + (@version ? "-#{@version}" : "") 
    end
    #
    # dirname of .pom of .jar file (in maven)
    #
    def dirname
      path = File.join(@group.split("."), @artifact)
      path = File.join(path, @version) if @version
      path
    end
    #
    # dependencies
    #
    def dependencies
      @xml.xpath("//#{@xmlns}dependency | //#{@xmlns}parent").each do |d|
        group = d.xpath("#{@xmlns}groupId")[0].text
        artifact = d.xpath("#{@xmlns}artifactId")[0].text
        version = d.xpath("#{@xmlns}version")[0].text rescue nil
        scope = d.xpath("#{@xmlns}scope")[0].text rescue nil
        optional = d.xpath("#{@xmlns}optional")[0].text rescue nil
        pom = Pom.new( { group: group, artifact: artifact, version: version, scopes: scope, optional: optional } )
#        puts "dependency pom #{pom.inspect}"
        yield pom
      end
    end
    #
    # resolve a pom
    # - download it
    # - download associated jars
    # - resolve dependencies
    #
    def resolve
#      puts "Resolving #{self}"
      # does it exist ?
      cached, result = download_to dirname
      if cached
        puts "Exists"
      else
        if result.is_a?(::String)
#          puts "Downloaded to #{result}"
        else
          puts "Failed download #{self}"
          return
        end
      end
      parse result
      dependencies do |pom|
        pom.parent = self
#        pom.resolve
      end
    end
  end
end
