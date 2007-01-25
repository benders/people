# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def person_image(uid, mtime = nil)
    mtime = mtime && mtime.to_i
    "<img class=\"photo\" src=\"#{url_for(:controller => 'person', :action => 'show', :id => uid, :format => 'jpg', :mtime => mtime)}\" alt=\"#{uid}\" />"
  end
  
  #
  # Custom Fragment Cache that allows the :mtime option
  #
  
  def cache(name = {}, options = nil, &block)
    @controller.cache_erb_fragment(block, name, options)
  end
end
