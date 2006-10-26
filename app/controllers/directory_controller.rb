class DirectoryController < ApplicationController
  before_filter :authenticate, :only => [ :show ]

  def index
    people = Group.new('Slackworks People').members.collect do |name| 
      Person.find(:attribute => 'uid', :value => name, :objects => true)
    end
    people.sort! { |a,b| b.modifytimestamp <=> a.modifytimestamp }
    
    page_size = 10
    start = 0
    if (@params[:page]) 
      start = (@params[:page].to_i - 1) * page_size
    end
    
    @pages = Paginator.new(self, people.size, page_size, @params[:page].to_i)
    @entries = people[start .. start + page_size - 1]
    
    render :layout => 'directory/index'
  end

  def show
    @person = Person.find(:attribute => 'uid', :value => @params[:id], :objects => true)
    if not [["TRUE"], ["FALSE"], [""]].include?(@person.show)
      render_model :object => @person
    end
  end

end
 