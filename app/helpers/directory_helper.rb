module DirectoryHelper

  def person_image(uid)
    "<img class=\"photo\" src=\"#{url_for(:controller => 'person', :action => 'image', :id => uid)}\" alt=\"#{uid}\" />"
  end
  
end
