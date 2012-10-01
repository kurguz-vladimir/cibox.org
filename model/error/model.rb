class ErrorModel
  
  include DataMapper::Resource

  property :id, Serial
  property :user, String, :index => true
  property :created_at, DateTime, :default => proc { DateTime.now }
  property :cmd, Text
  property :error, Text

end
