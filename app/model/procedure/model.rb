class ProcedureModel
  
  include DataMapper::Resource

  property :id, Serial
  property :user, String, :index => true
  property :name, String
  property :commands, Text
  property :private, Boolean, default: false

  def public?
    private == false
  end

end
