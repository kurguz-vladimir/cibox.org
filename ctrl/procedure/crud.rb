class Procedure::CRUD < E    
  
  map Procedure.base_url / :crud
  crudify ProcedureModel, exclude: '__stream_uuid__'

  def get_index id = nil
    @item = (id = id.to_i) > 0 ? ProcedureModel.first(id: id) : ProcedureModel.new
    render_partial
  end

end
