require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase

  def setup
    @person = Person.find('gnarg')
    @shown = Person.find(:all, :attribute => "show", :value=> "TRUE", :objects => true)
  end

  def test_read_one
    assert_kind_of Person,  @person
    assert_equal "Guymon", @person.sn
  end
  
  def test_read_many
    assert_equal "Benders", @shown[0].sn
    assert_equal "Spagettifoot", @shown[1].sn
  end

end