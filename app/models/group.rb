class Group < ActiveLDAP::Base
  ldap_mapping(:dnattr => 'cn',
               :prefix => 'ou=People',
               :classes => ['top', 'groupOfNames'])
  has_many(:members,
           :class_name => 'Person',
           :local_key => 'member',
           :foreign_key => 'dn')
end
