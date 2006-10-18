class DirectoryController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    shown = Person.find_all(:attribute => "show", :value => ["TRUE"], :objects => false)
    page_size = 20
    start = (@params[:page].to_i - 1 || 0) * page_size
    @pages = Paginator.new(self, shown.size, page_size, @params[:page].to_i)
    @entries = shown[start .. start + page_size].collect { |person| Person.new(person) }
  end

end
