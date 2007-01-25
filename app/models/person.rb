require 'vpim/vcard'

class Person < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People', 
               :classes => ['top', 'organizationalPerson', 
                            'inetOrgPerson', 'person']

  belongs_to :groups, :class => "Group",
             :many => "member"

  attr_accessor :instance_connection
  
  # By default there is a magical mapping of uid => userid,
  #  which returns the full DN.  I don't know why.  -xac
  def uid
    @ldap_data['uid'][0]
  end

  # Use the uid (username), as the Rails id
  alias_method :id, :uid
  
  def nickname
    self.cn.class == String ? self.cn : self.cn[1]
  end
  
  def fullname
    self.cn.class == String ? self.cn : self.cn[0]
  end

  def modifyTimestamp
    t = get_raw_attribute("modifyTimestamp").first
    Time.gm(t[0..3], t[4..5], t[6..7], t[8..9], t[10..11]).localtime
  end

  alias_method :mtime, :modifyTimestamp
  
  def createTimestamp
    t = get_raw_attribute("createTimestamp").first
    Time.gm(t[0..3], t[4..5], t[6..7], t[8..9], t[10..11]).localtime
  end

  alias_method :ctime, :createTimestamp
  
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
      #SeriesOfTubes.instance.set_connection(self.userid, conn)
      return true
    rescue LDAP::ResultError
      return false
    end
  end
  
  def Person.authenticate(uid, password)
    conf = LDAP_CONFIG
    conf[:allow_anonymous] = false
    conf[:bind_dn] = "uid=#{uid},#{self.prefix},#{conf[:base]}"
    conf[:password] = password
    conf[:store_password] = true
    auth_class = self.clone
    begin
      auth_class.establish_connection(conf)
      user = auth_class.find(conf[:bind_dn])
    rescue ActiveLdap::EntryNotFound, ActiveLdap::AuthenticationError
      return false
    end
    
    # stupid ActiveLdap trying to update the wrong attr
    user.instance_eval { @data['uid'] = @ldap_data['uid'] }
    
    MembersLounge.instance.add_member(uid, user)
    return true
  end
  
  def to_vcard
    card = Vpim::Vcard::Maker.make2 do |maker|
      maker.add_name do |name|
        name.given = self.gn
        name.family = self.sn
      end

      maker.nickname = self.nickname

      # XXX: not sure how to deal w/ address

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
  #  connection.modify(dn, unnormalized_entries, options)
  #  @@logger.debug("#save: modifying #{dn}")
  #  real_entries = Person.connection.instance_eval do
  #    parse_entries(unnormalized_entries)
  #  end
  #  SeriesOfTubes.instance.get_connection(dn).modify(dn, real_entries)
  #  @@logger.debug("#save: modify successful")
  #end
  
  private
  
  def get_raw_attribute(attribute)
    self.class.search(:prefix => "uid=#{self.uid}", :attributes => [attribute])[0][1][attribute]
  end
  
end