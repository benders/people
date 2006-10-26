module DirectoryHelper

  def person_image(uid)
    "<img src=\"#{image_path('people/' + uid + '.jpg')}\" onerror=\"this.src='#{image_path('people/gay.jpg')}'\"/>"
  end
  
end
