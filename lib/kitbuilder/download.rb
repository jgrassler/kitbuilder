require 'open-uri'

module Kitbuilder
  class Download
    def self.exists? uri
      print "#{uri.inspect}\e[K\r" # erase to end of line, back to column 0
      begin
        f = open(uri)
      rescue OpenURI::HTTPError
        return nil
      rescue URI::InvalidURIError
        STDERR.puts "\n\t  InvalidURIError"
        return nil
      rescue Exception => e
        STDERR.puts "\nopen(#{uri}) failed: #{e}"
        return nil
      end
      true
    end
    # lookup target in cache
    #  return :cached if cached
    #  return :downloaded if downloaded
    #  return nil if not found
    def self.download uri, target, verbose = nil
      if File.exists?(target)
        puts "#{target} cached in #{Dir.pwd}"
        :cached 
      else
        begin
          stream = open(uri)
          IO.copy_stream stream, target
          puts "#{target} downloaded to #{Dir.pwd} from #{uri}"
          return :downloaded
        rescue SocketError => e
          STDERR.puts "*** SocketError: #{uri} (#{e})"
        rescue Net::OpenTimeout => e
          STDERR.puts "*** OpenTimeout: #{uri} (#{e})"
        rescue OpenURI::HTTPError => e
          STDERR.puts "*** HTTPError: #{uri} (#{e})"
        rescue URI::InvalidURIError => e
          STDERR.puts "*** InvalidURI: #{uri} (#{e})"
        end
        nil
      end
    end
  end
end
