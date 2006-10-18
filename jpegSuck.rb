#!/usr/bin/ruby

require 'config/environment'

ActiveLDAP::Base.connect(YAML::load(IO.read('config/ldap.yml'))['development'])

Person.find_all(:attribute => 'show', :value => ['TRUE']).each do |name|

  person = Person.new(name)
  File.open(name + '.jpg', 'w') { |file| file.write(person.jpegphoto) }

  puts "got #{name}"

end


