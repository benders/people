require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < Test::Unit::TestCase

  def setup
    @admins = Group.find('Administrators')
  end
  
  def test_load_group
    assert_kind_of Group,  @admins
    assert_equal @admins.member[0], "uid=xac,ou=People,dc=slackworks,dc=com"
    assert_equal @admins.member[1], "uid=gnarg,ou=People,dc=slackworks,dc=com"
  end
  
end
