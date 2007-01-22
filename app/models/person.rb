class Person < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People', 
               :classes => ['top', 'organizationalPerson', 
                            'inetOrgPerson', 'person', ]

  belongs_to :groups, :class => "Group",
             :many => "member"

  attr_accessor :instance_connection

  def uid
    self.userid =~ /uid=(\w+),.*/
    $1
  end
  
  def nick_cn
    if self.cn.class == String
      self.cn
    else
      self.cn[1]
    end
  end
  
  def name_cn
    if self.cn.class == String
      self.cn
    else
      self.cn[0]
    end
  end

#  def modifytimestamp
#    @ldap_data['modifyTimestamp']
#  end
#
#  def mtime
#    m = @ldap_data['modifyTimestamp'][0]
#    Time.gm(m[0..3], m[4..5], m[6..7], m[8..9], m[10..11]).localtime
#  end
#  
#  def ctime
#    m = @ldap_data['createTimestamp'][0]
#    Time.gm(m[0..3], m[4..5], m[6..7], m[8..9], m[10..11]).localtime
#  end

  # can we do this with method_missing without messing up the parent?
  def note
    if (self.attributes.include?('note'))
      self.attributes['note']
    else
      nil
    end
  end
  
  def show
    if (self.attributes.include?('show'))
      self.attributes['show']
    else
      nil
    end
  end

  def login(password)
    begin
      conn = LDAP::Conn.open(LDAP_CONFIG[:host])
      conn.bind("uid=#{self.uid},#{self.prefix},#{LDAP_CONFIG[:base]}", password)
      SeriesOfTubes.instance.set_connection(self.uid, conn)
      #Person.establish_connection(:password_block => Proc.new { password })
      return true
    rescue LDAP::ResultError
      return false
    end
  end

end