class RMXActionSheet < UIActionSheet

  def init
    s = super
    self.delegate = self
    s
  end

  def actionSheet(actionSheet, clickedButtonAtIndex:buttonIndex)
    title = actionSheet.buttonTitleAtIndex(buttonIndex)
    RMX.new(self).trigger(:clickedButton, { :index => buttonIndex, :title => title })
  end

end
