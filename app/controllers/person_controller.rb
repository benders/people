class PersonController < ApplicationController
  before_filter :authenticate, :only => [ :show ]

  def edit
    @person = Person.find(params[:id])
  end

  def image
    person = Person.find(params[:id])
    if (person.respond_to?(:jpegPhoto) && person.jpegPhoto)
      send_data(person.jpegPhoto, :type => 'image/jpeg', :disposition => 'inline')
    else
      send_file('public/images/people/gay.jpg', :type => 'image/jpeg', :disposition => 'inline')
    end
  end
  
  def index
    people = Group.find('Slackworks People').member.collect do |name| 
      Person.find(name)
    end
    #people.sort! { |a,b| b.modifytimestamp <=> a.modifytimestamp }
    
    page_size = 10
    start = 0
    if (params[:page]) 
      start = (params[:page].to_i - 1) * page_size
    end
    
    @pages = Paginator.new(self, people.size, page_size, params[:page].to_i)
    @entries = people[start .. start + page_size - 1]
    
    render :layout => 'person/index'
  end
  
  def show
    @person = Person.find(params[:id])
    
    respond_to do |format|
      format.html
      format.xml do
        @person.jpegPhoto = nil
        @person.show = nil
        render :xml => @person.to_xml
      end 
      format.vcf do
        send_data @person.to_vcard, :filename => "#{@person.uid}.vcf",
          :type => 'text/directory'
      end 
    end
  end
  
  def update
    @person = Person.find(params[:id])
    
    if @person.update_attributes(params[:person])
      flash[:notice] = 'Successfully updated.'
        redirect_to person_url(@person.uid)
      else
        render edit_person_url(@person.uid)
      end  
  end
  
end
