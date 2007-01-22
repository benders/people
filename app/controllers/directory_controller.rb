class DirectoryController < ApplicationController
  before_filter :authenticate, :only => [ :show ]

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
    
    render :layout => 'directory/index'
  end

  def show
    @person = Person.find(:attribute => 'uid', :value => params[:id], :objects => true)
    @attrs = [:cn, :roomNumber, :mail, :note, :jabber, :aim, :icq, 
              :homePostalAddress, :labeledURI, :mtime]
              
    # for acts_as_renderable
    #if not [["TRUE"], ["FALSE"], [""]].include?(@person.show)
    #  render_model :object => @person
    #end
  end
  
  def edit
    @person = Person.find(:attribute => 'uid', :value => params[:id], :objects => true)
  end
  
  def update
    @person = Person.new(params[:id])
    
    # XXX: how do we get the current user's instance_connection?
    #@person.instance_connection = ??
    #
    # update attributes
    # write
    # render show or failure
  end

end
 