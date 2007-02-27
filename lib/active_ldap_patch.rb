#
# include this into your class which inherits from ActiveLdap::Base
#
module ActiveLdapPatch
  def patched?
    true
  end

  #
  # Copied from ActiveRecord 1.15.2
  #
  def attributes=(new_attributes)
    return if new_attributes.nil?
    attributes = new_attributes.dup
    attributes.stringify_keys!
    
    multi_parameter_attributes = []
    remove_attributes_protected_from_mass_assignment(attributes).each do |k, v|
      k.include?("(") ? multi_parameter_attributes << [ k, v ] : send(k + "=", v)
    end

    assign_multiparameter_attributes(multi_parameter_attributes)
  end


  def update_attributes!(attributes)
    self.attributes = attributes
    save!
  end

  #
  # Disable for now, this part of AR is very confusing
  #
  def assign_multiparameter_attributes(pairs)
    unless pairs.empty?
      raise "No support (currently) for multi_parameter_attributes: #{pairs}"
    end
  end

end
