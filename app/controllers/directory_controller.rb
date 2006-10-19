class DirectoryController < ApplicationController
  before_filter :authenticate, :only => [ :show ]

  def index
    list
    render :action => 'list'
  end

  def list
    shown = Person.find_all(:attribute => "show", :value => ["TRUE"], :objects => false)
    page_size = 20
    start = 0
    if (@params[:page]) 
      start = (@params[:page].to_i - 1) * page_size
    end
    @pages = Paginator.new(self, shown.size, page_size, @params[:page].to_i)
    @entries = shown[start .. start + page_size - 1].collect { |person| Person.new(person) }
  end

  def show
    @person = Person.find(:attribute => 'uid', :value => @params[:id], :objects => true)
  end

end
 