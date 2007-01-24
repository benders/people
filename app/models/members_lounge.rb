require 'singleton'

class MembersLounge
  include Singleton
  
  def initialize
    @members = {}
  end
  
  def member(uid)
    @members[uid]
  end
  
  def add_member(uid, person)
    @members[uid] = person
  end
end
