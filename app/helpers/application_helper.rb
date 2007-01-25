# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def person_image(uid)
    "<img class=\"photo\" src=\"#{url_for(:controller => 'person', :action => 'show', :id => uid, :format => 'jpg')}\" alt=\"#{uid}\" />"
  end
end
