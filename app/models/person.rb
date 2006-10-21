class Person < ActiveLDAP::Base
  ldap_mapping :dnattr => 'uid', :prefix => 'ou=People', :classes => ['posixAccount']

  def Person.login(username, password)
    begin
      # reconnect as a particular user
      ActiveLDAP::Base.close
      ActiveLDAP::Base.connection = LDAP::Conn.open(LDAP_CONFIG[:host])
      ActiveLDAP::Base.connection.bind("uid=#{username},ou=People,dc=slackworks,dc=com", password)
      return true
    rescue LDAP::ResultError
      return false
    end
  end

  def get_note
    if (self.attributes.include?('note'))
      self.note
    else
      ''
    end
  end

  ### WARNING: monkey-patching of ActiveLDAP:Base below ###

  # everything except jpegphoto, userpassword
  # probly want to pare this down to just what we show on the page
  # but this is ok for now
  @attributes = ["+", "modifytimestamp", "otherfacsimiletelephonenumber", "l", "destinationindicator", 
    "hometelephonenumber", "seealso", "streetaddress", "jabber", 
    "assistantphone", "organizationalunitname", "organizationname", 
    "callbackphone", "homefax", "carphone", "commonname", "localityname", 
    "x121address", "o", "freebusyuri", "photo", "preferreddeliverymethod", 
    "calendaruri", "usersmimecertificate", "loginshell", 
    "homepostaladdress", "ou", "shadowmin", "gn", "teletexterminalidentifier", 
    "mobiletelephonenumber", "assistantname", "spousename", 
    "homefacsimiletelephonenumber", "registeredaddress", "shadowlastchange", 
    "surname", "show", "physicaldeliveryofficename", "objectclass", 
    "description", "displayname", "secretary", "mail", "shadowflag", 
    "postaladdress", "managername", "preferredlanguage", "x500uniqueidentifier", 
    "street", "mobile", "employeetype", "uidnumber", "shadowmax", 
    "shadowwarning", "aim", "otherfax", "companyphone", "audio", "userid", "sn", 
    "msn", "note", "businessrole", "internationalisdnnumber", "labeleduri", 
    "postalcode", "categories", "primaryphone", "radio", "homephone", 
    "anniversary", "fileas", "usercertificate", "telephonenumber", 
    "shadowexpire", "birthdate", "pagertelephonenumber", "rfc822mailbox", "host", 
    "manager", "givenname", "departmentnumber", "fax", "st", 
    "carlicense", "pager", "postofficebox", "facsimiletelephonenumber", 
    "businesscategory", "mailer", "icq", "initials", "homedirectory", "mua", 
    "userpkcs12", "gidnumber", "telexnumber", "employeenumber", "dob", 
    "otherphone", "roomnumber", "cn", "gecos", "shadowinactive", "category", 
    "tty", "stateorprovincename", "telex", "otherpostaladdress", "uid", "yahoo", 
    "title"]

  # find
  #
  # Finds the first match for value where |value| is the value of some 
  # |field|, or the wildcard match. This is only useful for derived classes.
  # usage: Subclass.find(:attribute => "cn", :value => "some*val", :objects => true)
  #        Subclass.find('some*val')
  #
  def Person.find(config='*')
    Person.reconnect if Person.connection.nil? and Person.can_reconnect?

     if self.class == Class
     klass = self.ancestors[0].to_s.split(':').last
      real_klass = self.ancestors[0]
    else 
      klass = self.class.to_s.split(':').last
      real_klass = self.class
    end

    # Allow a single string argument
    attr = dnattr()
    objects = @@config[:return_objects]
    val = config
    filter = nil
    # Or a hash
    if config.respond_to?(:has_key?)
      attr = config[:attribute] unless config[:attribute].nil?
      val = config[:value] || '*'
      objects = config[:objects] unless config[:objects].nil?
      if not config[:filter].nil?
        if not config[:value].nil? or not config[:attribute].nil?
          @logger.warn('find: :filter argument overrides :value and :attribute') 
        end
        filter = config[:filter]
      end
    end
    # Determine the search filter
    filter = "(#{attr}=#{val})" if filter.nil? 

    Person.connection(RuntimeError.new("Failed in #{self.class}#find(#{config.inspect})")) do |conn|
      # Get some attributes
      conn.search(base(), ldap_scope(), filter, attrs=@attributes)  do |m|
      #conn.search(base(), ldap_scope(), filter)  do |m|
        # Extract the dnattr value
        dnval = m.dn.split(/,/)[0].split(/=/)[1]

        if objects
          return real_klass.new(m)
        else
          return dnval
        end
      end
    end
    # If we're here, there were no results
    return nil
  end
  #private_class_method :find

  # find_all
  #
  # Finds all matches for value where |value| is the value of some 
  # |field|, or the wildcard match. This is only useful for derived classes.
  def Person.find_all(config='*')
    Person.reconnect if Person.connection.nil? and Person.can_reconnect?
     
    if self.class == Class
      real_klass = self.ancestors[0]
    else 
      real_klass = self.class
    end

    # Allow a single string argument
    val = config
    attr = dnattr()
    objects = @@config[:return_objects]
    filter = nil
    # Or a hash
    if config.respond_to?(:has_key?)
      val = config[:value] || '*'
      attr = config[:attribute] unless config[:attribute].nil?
      objects = config[:objects] unless config[:objects].nil?
      if not config[:filter].nil?
        if not config[:value].nil? or not config[:attribute].nil?
          @logger.warn('find_all: :filter argument overrides :value and :attribute') 
        end
        filter = config[:filter]
      end
    end
    # Determine the search filter
    filter = "(#{attr}=#{val})" if filter.nil? 

    matches = []
    Person.connection(RuntimeError.new("Failed in #{self.class}#find_all(#{config.inspect})")) do |conn|
      # Get some attributes
      conn.search(base(), ldap_scope(), filter, attrs=@attributes)  do |m|
        # Extract the dnattr value
        dnval = m.dn.split(/,/)[0].split(/=/)[1]

        if objects
          matches.push(real_klass.new(m))
        else
          matches.push(dnval)
        end
      end
    end
    return matches
  end
  #private_class_method :find_all
  
  # apply_objectclass
  #
  # objectClass= special case for updating appropriately
  # This updates the objectClass entry in @data. It also
  # updating all required and allowed attributes while
  # removing defined attributes that are no longer valid
  # given the new objectclasses.
  def apply_objectclass(val)
    #@@logger.debug("stub: objectClass=(#{val.inspect}) called")
    new_oc = val
    new_oc = [val] if new_oc.class != Array
    if defined?(@last_oc).nil?
      @last_oc = false
    end
    return new_oc if @last_oc == new_oc

    # Store for caching purposes
    @last_oc = new_oc.dup

    # Set the actual objectClass data
    define_attribute_methods('objectClass')
    @data['objectClass'] = new_oc.uniq

    # Build |data| from schema
    # clear attr_method mapping first
    @attr_methods = {}
    @must = []
    @may = []
    new_oc.each do |objc|
      # get all attributes for the class
      attributes = Person.schema.class_attributes(objc.to_s)
      @must += attributes[:must]
      @may += attributes[:may]
    end
    @may += ['modifytimestamp','modifiersname','createtimestamp','creatorsname']
    @must.uniq!
    @may.uniq!
    (@must+@may).each do |attr|
        # Update attr_method with appropriate
        define_attribute_methods(attr)
    end
    define_attribute_methods('modifytimestamp')
  end

end