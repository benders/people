class Group < ActiveLdap::Base
  ldap_mapping(:dn_attribute => 'cn',
               :prefix => 'ou=People',
               :classes => ['top', 'groupOfNames'])
  has_many(:members, :class => 'Person',
           :wrap => 'member')
end
