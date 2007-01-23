require 'vpim/vcard'

class Person < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People', 
               :classes => ['top', 'organizationalPerson', 
                            'inetOrgPerson', 'person', ]

  belongs_to :groups, :class => "Group",
             :many => "member"

  attr_accessor :instance_connection

  def id
    uid
  end

  def uid
    self.userid =~ /uid=(\w+),.*/
    $1
  end
  
  def nickname
    if self.cn.class == String
      self.cn
    else
      self.cn[1]
    end
  end
  
  def fullname
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
      SeriesOfTubes.instance.set_connection(self.userid, conn)
      return true
    rescue LDAP::ResultError
      return false
    end
  end
  
  def Person.authenticate(uid, password)
    conf = LDAP_CONFIG
    conf[:allow_annonymous] = false
    conf[:bind_dn] = "uid=#{uid},#{self.prefix},#{conf[:base]}"
    conf[:password] = password
    auth_class = self.clone
    auth_class.establish_connection(conf)
    auth_class.find(conf[:bind_dn])
  end
  
  def to_vcard
    card = Vpim::Vcard::Maker.make2 do |maker|
      maker.add_name do |name|
        name.given = self.gn
        name.family = self.sn
      end

      maker.nickname(self.nickname)

      # not sure how to deal w/ address

      maker.add_tel(self.homeTelephoneNumber) do |tel|
        tel.location = 'home'
      end unless self.homeTelephoneNumber.blank?
      maker.add_tel(self.mobileTelephoneNumber) do |tel|
        tel.location = 'mobile'
      end unless self.mobileTelephoneNumber.blank?

      maker.add_email(self.mail) unless self.mail.blank?
      maker.add_impp("xmpp:#{self.jabber}") unless self.jabber.blank?
    end
    card.to_s
  end
  
  # WARNING: here begins monkey-patching:
  # replaces ActiveLdap::Base.modify
  #def Person.modify(dn, entries, options={})
  #  unnormalized_entries = entries.collect do |type, key, value|
  #    [type, key, unnormalize_attribute(key, value)]
  #  end
  #  #connection.modify(dn, unnormalized_entries, options)
  #  @@logger.debug("#save: modifying #{dn}")
  #  real_entries = Person.connection.instance_eval do
  #    parse_entries(unnormalized_entries)
  #  end
  #  SeriesOfTubes.instance.get_connection(dn).modify(dn, real_entries)
  #  @@logger.debug("#save: modify successful")
  #end
  
end