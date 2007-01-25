#  Created by Nic Benders on 2007-01-25.

class String
  def ldap_to_time
    Time.gm(self[0..3], self[4..5], self[6..7], self[8..9], self[10..11]).localtime
  end
end
