class Person < ActiveLDAP::Base
  ldap_mapping :dnattr => 'uid', :prefix => 'ou=People', 
               :classes => ['top','posixAccount', 'person', 'organizationalPerson', 
                            'inetOrgPerson', 'person', ]
  acts_as_renderable :method => :show_view, :controller => 'directory', :action => 'show'

  attr_accessor :instance_connection

  def modifytimestamp
    @ldap_data['modifyTimestamp']
  end

  def mtime
    m = @ldap_data['modifyTimestamp'][0]
    Time.gm(m[0..3], m[4..5], m[6..7], m[8..9], m[10..11]).localtime
  end
  
  def ctime
    m = @ldap_data['createTimestamp'][0]
    Time.gm(m[0..3], m[4..5], m[6..7], m[8..9], m[10..11]).localtime
  end

  # can we do this with method_missing without messing up the parent?
  def note
    if (self.attributes.include?('note'))
      attribute_method('note')
    else
      ['']
    end
  end
  
  def show_view
    show[0]
  end
  
  def show
    if (self.attributes.include?('show'))
      attribute_method('show')
    else
      ['']
    end
  end

  def login(password)
    begin
      @instance_connection = LDAP::Conn.open(LDAP_CONFIG[:host])
      # need to get rid of the prefix
      @instance_connection.bind("uid=#{self.uid[0]},ou=People,#{LDAP_CONFIG[:base]}", password)
      return true
    rescue LDAP::ResultError
      return false
    end
  end

  ### WARNING: monkey-patching of ActiveLDAP::Base below ###

  # all possible except jpegphoto, userpassword
  # probly want to pare this down to just what we show on the page
  # but this is ok for now
  @only = ["+", "otherfacsimiletelephonenumber", "l", "destinationindicator", 
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
      conn.search(base(), ldap_scope(), filter, attrs=@only)  do |m|
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
      conn.search(base(), ldap_scope(), filter, attrs=@only)  do |m|
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
  
    # save
    #
    # Save and validate this object into LDAP
    # either adding or replacing attributes
    # TODO: Relative DN support
    def save
      @data = @data.delete_if { |k,v| k == nil }
    
      @@logger.debug("stub: save called")
      # Validate against the objectClass requirements
      validate

      # Put all changes into one change entry to ensure
      # automatic rollback upon failure.
      entry = []


      # Expand subtypes to real ldap_data entries
      # We can't reuse @ldap_data because an exception would leave
      # an object in an unknown state
      @@logger.debug("#save: dup'ing @ldap_data")
      ldap_data = Marshal.load(Marshal.dump(@ldap_data))
      @@logger.debug("#save: dup finished @ldap_data")
      @@logger.debug("#save: expanding subtypes in @ldap_data")
      ldap_data.keys.each do |key|
        ldap_data[key].each do |value|
          if value.class == Hash
            suffix, real_value = extract_subtypes(value)
            if ldap_data.has_key? key + suffix
              ldap_data[key + suffix].push(real_value)
            else
              ldap_data[key + suffix] = real_value
            end
            ldap_data[key].delete(value)
          end
        end
      end
      @@logger.debug('#save: subtypes expanded for @ldap_data')

      # Expand subtypes to real data entries, but leave @data alone
      @@logger.debug('#save: duping @data')
      data = Marshal.load(Marshal.dump(@data))
      @@logger.debug('#save: finished duping @data')

      @@logger.debug('#save: removing disallowed attributes from @data')
      bad_attrs = @data.keys - (@must+@may)
      bad_attrs.each do |removeme|
        data.delete(removeme) 
      end
      @@logger.debug('#save: finished removing disallowed attributes from @data')


      @@logger.debug('#save: expanding subtypes for @data')
      data.keys.each do |key|
        data[key].each do |value|
          if value.class == Hash
            suffix, real_value = extract_subtypes(value)
            if data.has_key? key + suffix
              data[key + suffix].push(real_value)
            else
              data[key + suffix] = real_value
            end
            data[key].delete(value)
          end
        end
      end
      @@logger.debug('#save: subtypes expanded for @data')

      if @exists
        # Cycle through all attrs to determine action
        action = {}

        replaceable = []
        # Now that all the subtypes will be treated as unique attributes
        # we can see what's changed and add anything that is brand-spankin'
        # new.
        @@logger.debug('#save: traversing ldap_data determining replaces and deletes')
        ldap_data.each do |pair|
          suffix = ''
          binary = 0

          name, *suffix_a = pair[0].split(/;/)
          suffix = ';'+ suffix_a.join(';') if suffix_a.size > 0
          name = @attr_methods[name]
          name = pair[0].split(/;/)[0] if name.nil? # for objectClass, or removed vals
          value = data[name+suffix]
          # If it doesn't exist, don't freak out.
          value = [] if value.nil?

          # Detect subtypes and account for them
          binary = LDAP::LDAP_MOD_BVALUES if Person.schema.binary? name

          replaceable.push(name+suffix)
          if pair[1] != value
            # Create mod entries
            if not value.empty?
              # Ditched delete then replace because attribs with no equality match rules
              # will fails
              @@logger.debug("#save: pdating attribute of existing entry:  #{name+suffix}: #{value.inspect}")
              entry.push(LDAP.mod(LDAP::LDAP_MOD_REPLACE|binary, name + suffix, value))
            else
              # Since some types do not have equality matching rules, delete doesn't work
              # Replacing with nothing is equivalent.
              @@logger.debug("#save: removing attribute from existing entry:  #{name+suffix}")
              entry.push(LDAP.mod(LDAP::LDAP_MOD_REPLACE|binary, name + suffix, []))
            end
          end
        end
        @@logger.debug('#save: finished traversing ldap_data')
        @@logger.debug('#save: traversing data determining adds')
        data.each do |pair|
          suffix = ''
          binary = 0

          name, *suffix_a = pair[0].split(/;/)
          suffix = ';' + suffix_a.join(';') if suffix_a.size > 0
          name = @attr_methods[name]
          name = pair[0].split(/;/)[0] if name.nil? # for obj class or removed vals
          value = pair[1]
          # Make sure to change this to an Array if there was mistake earlier.
          value = [] if value.nil?

          if not replaceable.member? name+suffix
            # Detect subtypes and account for them
            binary = LDAP::LDAP_MOD_BVALUES if Person.schema.binary? name
            @@logger.debug("#save: adding attribute to existing entry:  #{name+suffix}: #{value.inspect}")
            # REPLACE will function like ADD, but doesn't hit EQUALITY problems
            # TODO: Added equality(attr) to Schema2
            entry.push(LDAP.mod(LDAP::LDAP_MOD_REPLACE|binary, name + suffix, value)) unless value.empty?
          end
        end
        @@logger.debug('#save: traversing data complete')
        #Person.connection(SaveError.new(
        #                "Failed to modify: '#{entry}'")) do |conn|
          @@logger.debug("#save: modifying #{@dn}")
          @instance_connection.modify(@dn, entry)
          @@logger.debug('#save: modify successful')
        #end
      else # add everything!
        @@logger.debug('#save: adding all attribute value pairs')
        @@logger.debug("#save: adding #{@attr_methods[dnattr()].inspect} = #{data[@attr_methods[dnattr()]].inspect}")
        entry.push(LDAP.mod(LDAP::LDAP_MOD_ADD, @attr_methods[dnattr()], 
          data[@attr_methods[dnattr()]]))
        @@logger.debug("#save: adding objectClass = #{data[@attr_methods['objectClass']].inspect}")
        entry.push(LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectClass', 
          data[@attr_methods['objectClass']]))
        data.each do |pair|
          if pair[1].size > 0  and pair[0] != 'objectClass' and pair[0] != @attr_methods[dnattr()]
            # Detect subtypes and account for them
            if Person.schema.binary? pair[0].split(/;/)[0]
              binary = LDAP::LDAP_MOD_BVALUES 
            else
              binary = 0
            end
            @@logger.debug("#save: adding attribute to new entry:  #{pair[0].inspect}: #{pair[1].inspect}")
            entry.push(LDAP.mod(LDAP::LDAP_MOD_ADD|binary, pair[0], pair[1]))
          end
        end
        #Person.connection(SaveError.new(
        #                "Failed to add: '#{entry}'")) do |conn|
          @@logger.debug("#save: adding #{@dn}")
          @instance_connection.add(@dn, entry)
          @@logger.debug("#write: add successful")
          @exists = true
        #end
      end
      @@logger.debug("#save: resetting @ldap_data to a dup of @data")
      @ldap_data = Marshal.load(Marshal.dump(data))
      # Delete items disallowed by objectclasses. 
      # They should have been removed from ldap.
      @@logger.debug('#save: removing attributes from @ldap_data not sent in data')
      bad_attrs.each do |removeme|
        @ldap_data.delete(removeme) 
      end
      @@logger.debug('#save: @ldap_data reset complete')
      @@logger.debug('stub: save exitted')
      self
    end
end
