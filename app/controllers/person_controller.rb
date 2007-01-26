require 'ldap-patches'

class PersonController < ApplicationController
  before_filter :authenticate, :only => [ :edit, :update ]
  before_filter :user_connect
  session :new_session => false

  def edit
    @person = Person.find(params[:id])
  end
  
  def index
    people = Group.find('Slackworks People').member.collect do |dn| 
      # Return the uid component of the DN only
      /^uid=([^,]+),#{Group.base}$/.match(dn)[1]
    end
    
    timestamp = Hash.new
    Person.search(:attributes => ['uid', 'modifyTimestamp'], :scope => :one).each do |person|
      uid = person[1]['uid'][0]
      modifyTimestamp = person[1]['modifyTimestamp'][0]
      timestamp[uid] = modifyTimestamp.ldap_to_time
    end

    # Create a small anon Class to hand down to the templates, 
    #  we don't want to instantiate a full Person unless the
    #  cache is stale.
    klass = Struct.new(nil, :uid, :modifyTimestamp)
    people.collect! do |uid| 
      next unless timestamp[uid]
      klass.new(uid, timestamp[uid] )
    end
    people.sort! { |a,b| b.modifyTimestamp <=> a.modifyTimestamp }
    
    page_size = 10
    start = 0
    if (params[:page]) 
      start = (params[:page].to_i - 1) * page_size
    end
    
    @pages = Paginator.new(self, people.size, page_size, params[:page].to_i)
    @entries = people[start .. start + page_size - 1]
  end
  
  def show
    @person = Person.find(params[:id]) unless params[:format] == 'jpg' 
    
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
      format.jpg do
        show_jpg
      end
    end
  end
  
  def update
    @person = Person.find(session[:user])
    
    # stupid ActiveLdap trying to update the wrong attr
    #@person.instance_eval { @data['uid'] = @person.uid }
    #@person.instance_eval { @ldap_data['uid'] = @person.uid }
    
    if @person.update_attributes(params[:person])
      flash[:notice] = 'Successfully updated.'
        redirect_to person_url(@person.uid)
      else
        render edit_person_url(@person.uid)
      end  
  end

  private
  
  def show_jpg
    fragment_name = fragment_cache_key({:action => 'show', :id => params[:id], :format => params[:format], :mtime => nil})

    logger.info("Checking cache for #{fragment_name}")
    content = read_fragment(fragment_name, {:mtime => params[:mtime]})
        
    unless content
      logger.info("Retreiving image for #{params[:id]}")
      person = Person.find(params[:id])
      if (person.respond_to?(:jpegPhoto) && person.jpegPhoto)
        content = person.jpegPhoto
      else
        content = File.new("public/images/people/gay.jpg").read
      end
      logger.info("Writing cache for #{fragment_name}")
      write_fragment(fragment_name, content, {:mtime => Time.now})
    end
    expires_in IMAGE_EXPIRES, :private => false, :public => true
    response.headers["Last-Modified"] = Time.at(params[:mtime].to_i).httpdate
    send_data( content, :type => 'image/jpeg', :disposition => 'inline' )
  end
end
