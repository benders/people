require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase

  def setup
    @person = Person.new('gnarg')
    @shown = Person.find_all(:attribute => "show", :value=> ["TRUE"], :objects => true)
  end

  def test_read_one
    assert_kind_of Person,  @person
    assert_equal ["Guymon"], @person.sn
  end
  
  def test_read_many
    assert_equal ["Benders"], @shown[0].sn
    assert_equal ["Guymon"], @shown[1].sn
    assert_equal ["Spagettifoot"], @shown[2].sn
  end

end