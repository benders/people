require 'vpim/vcard'
require 'ldap-patches'
require 'mini_magick'

class Person < ActiveLdap::Base
  include ::ActiveLdapPatch
  
  ldap_mapping :dn_attribute => 'uid', :prefix => 'ou=People', 
               :classes => ['top', 'organizationalPerson', 
                            'inetOrgPerson', 'person']

  # usage: Person#groups.include?(Group#)
  #   or the faster
  # Person#groups.map{ |g| g.dn }.include?("cn=Administrators,#{Group.base}")
  belongs_to :groups,
             :many => "member",
             :foreign_key => "dn"
  
  before_save :reformat_photo
  
  def Person.admin?(uid)
    Group.find('Administrators').member.include?("#{Person.dn_attribute}=#{uid},#{Person.base}")
  end
             
  def admin?
    self.groups.map { |g| g.dn }.include?("cn=Administrators,#{Group.base}")
  end
  
  # By default there is a magical mapping of uid => userid,
  #  which returns the full DN.  I don't know why.  -xac
  def uid
    @ldap_data['uid'][0]
  end

  # Use the uid (username), as the Rails id
  alias_method :id, :uid
  
  def jpegPhoto=(photo)
    if photo.is_a?(Array)
      photo = photo.first
    end
    
    if photo.respond_to?(:read)
      data = photo.read
    elsif photo.is_a?(String)
      data = photo
    else
      raise "Unsupported jpegPhoto class #{photo.class.to_s}"
    end
    set_attribute('jpegPhoto', data)
  end
  
  def reformat_photo
    image = MiniMagick::Image.from_blob(self.jpegPhoto)
    unless image.is_a?(MiniMagick::Image)
      raise "Could not recognize image"
    end
    image.resize "200x200"
    image.format "jpg"

    data = File.open(image.path) { |f| f.read }
    unless data.size > 0
      raise "Invalid resulting jpegPhoto"
    end
    self.jpegPhoto = data
  end
  
  def nickname
    self.cn.class == String ? self.cn : self.cn[1]
  end
  
  def fullname
    self.cn.class == String ? self.cn : self.cn[0]
  end

  def modifyTimestamp_before_type_cast
    get_raw_attribute("modifyTimestamp").first
  end
  
  def modifyTimestamp
    modifyTimestamp_before_type_cast.ldap_to_time
  end

  alias_method :mtime, :modifyTimestamp
  
  def createTimestamp_before_type_cast
    get_raw_attribute("createTimestamp").first
  end
  
  def createTimestamp
    modifyTimestamp_before_type_cast.ldap_to_time
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

#  def login(password)
#    conf = LDAP_CONFIG
#    conf[:allow_anonymous] = false
#    conf[:bind_dn] = self.dn
#    conf[:password] = password
#    conf[:store_password] = true
#    ActiveLdap::Base.define_configuration(self.uid, conf)
#    begin
#      ActiveLdap::Base.establish_connection(conf)
#      return true
#    rescue LDAP::ResultError
#      return false
#    end
#  end
  
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
  
  private
  
  def get_raw_attribute(attribute)
    self.class.search(:prefix => "uid=#{self.uid}", :attributes => [attribute])[0][1][attribute]
  end
  
end