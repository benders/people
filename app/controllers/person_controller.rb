class PersonController < ApplicationController

  def image
    person = Person.find(params[:id])
    if (person.respond_to?(:jpegPhoto) && person.jpegPhoto)
      send_data(person.jpegPhoto, :type => 'image/jpeg', :disposition => 'inline')
    else
      send_file('public/images/people/gay.jpg', :type => 'image/jpeg', :disposition => 'inline')
    end
  end

end
