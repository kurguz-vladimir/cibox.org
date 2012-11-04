class Array

  def shellify escape_spaces = false
    escape_spaces ?
      self.map { |e| e.to_s.shellify.escape_spaces } :
      self.map { |e| e.to_s.shellify }
  end

end
