class String

  def / path
    [self, self =~ /\/\Z/ || path.to_s =~ /\A\// ? '' : '/', path].join
  end

  def to_url
    self.gsub(/[^\w|\d|\-]/, '_')
  end

  def to_md5
    ::Digest::MD5.hexdigest self
  end

  def to_password email = nil, salt = nil
    ::Digest::SHA2.new(512).update [email, self, salt]*'::'
  end

  def escape_spaces
    self.gsub(/\s/, '\\\0040')
  end

end
