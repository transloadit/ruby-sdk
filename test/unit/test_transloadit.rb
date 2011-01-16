require 'test_helper'

class TestTransloadit < MiniTest::Unit::TestCase
  def test_initializer_works
    key    = 'a'
    secret = 'b'
    t      = Transloadit.new(:key => key, :secret => secret)
    
    assert_equal key,    t.key
    assert_equal secret, t.secret
  end
  
  def test_initializer_requires_key
    assert_raises ArgumentError do
      Transloadit.new(:secret => 'x')
    end
  end
  
  def test_initializer_does_not_require_secret
    assert_kind_of Transloadit, Transloadit.new(:key => 'x')
  end
  
  def test_initializer_with_no_arguments
    assert_raises ArgumentError do
      Transloadit.new
    end
  end
end
