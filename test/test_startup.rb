require File.join(File.dirname(__FILE__), 'helper')

class Startup_test < Test::Unit::TestCase

  def test_startup
    # constructor needs 3 arguments
    assert_raise ArgumentError do
      Kitbuilder::Kitbuilder.new
    end
  end

end
