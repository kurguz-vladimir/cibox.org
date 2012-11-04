function ECrudifyBootstrap(baseURL, callbacks) {

  var ID = 'crudify_modal_' + baseURL.replace(/[^\w|\d|\-]/g, '_');
  var ID_PREFIXED = '#' + ID;

  CLASS_DATA = {};
  var class_data = jQuery.extend(true, {}, ECrudifyBootstrap.CLASS_DATA);
  var instance_data = {};

  this.create = function (data) {
    $(ID_PREFIXED +'-delete_button').hide();
    $(ID_PREFIXED + '-item_id').val(null);
    this.dispose_interface(data);
  }

  this.update = function (item_id, data) {
    $(ID_PREFIXED +'-delete_button').show();
    $(ID_PREFIXED + '-item_id').val(item_id);
    this.dispose_interface(item_id, data);
  }

  this.dispose_interface = function(item_id, data) {
    if(jQuery.isPlainObject(item_id)) {
      data = item_id; item_id = '';
    }
    instance_data = data || {};
    $.get(
      baseURL + '/' + (item_id || ''),
      jQuery.extend(true, {}, class_data, instance_data),
      function (response) {
        $(ID_PREFIXED).modal();
        $(ID_PREFIXED + '-error').html(null).hide();
        $(ID_PREFIXED + '-form').html(response);
        $(ID_PREFIXED + '-form :input:visible:first').focus();
      }
    );
  }

  // do not use delete until all browsers will definitely use ECMAScript v.5,
  // cause delete throws syntax error in ECMAScript lass than 5,
  // which are yet widely adopted by the most browsers.
  this.remove = function () {
    if(confirm('This action can not be undone! Continue with deletion?') == false)
      return false; 
    this.invoke_request('delete');
  }

  this.save = function () {
    this.invoke_request('save');
  }

  this.hide = function () {
    $(ID_PREFIXED).modal('hide');
  }

  this.invoke_request = function (action, item_id, data) {
    if(jQuery.isPlainObject(item_id)) {
      var data    = item_id;
      var item_id = '';
    } else {
      if (item_id == undefined)
        var item_id = $(ID_PREFIXED + '-item_id').val() || '';
    }
    if(!jQuery.isPlainObject(data)){
      var data = {};
      // TODO: handle forms with nested data
      jQuery.each($(ID_PREFIXED + '-form').serializeArray(), function () {
        data[this.name] = this.value || '';
      });
    }

    // it is CRITICAL given data to have priority over instance data 
    // and instance_data to have priority over class data!
    var data = jQuery.extend(true, {}, class_data, instance_data, data);

    var url  = baseURL + '/' + item_id;
    var type = 'GET';
    var callback = null;
    if (action == 'save') {
      if ( item_id.toString().length > 0 ) { 
        type     = 'PUT';
        callback = 'edit';
      } else {
        type     = 'POST';
        callback = 'create';
      }
    } else if (action == 'delete'){
      type     = 'DELETE';
      callback = 'delete';
    } else {
      alert('unknown action given'); return false;
    }
    $.ajax({
      url:  url,
      type: type,
      data: data,
      complete: function (xhr, status) {
        if (status == 'success'){
          if(jQuery.isFunction(callbacks))
            callbacks.call(this, callback, data, xhr);
        } else
          $(ID_PREFIXED + '-error').html(xhr.responseText).show();
      }
    });
  }

  this.html = function (instance_name) {
    $('body').append('\
    <div class="modal hide" id="'+ ID +'"> \
      <div class="modal-body"> \
        <input class="hide" id="'+ ID +'-item_id" /> \
        <form id="'+ ID +'-form"></form> \
        <div class="alert alert-error hide" id="'+ ID +'-error"></div> \
      </div> \
      <div class="modal-footer"> \
        <div class="row"> \
          <div class="span"> \
            <button class="btn btn-danger" id="'+ ID +'-delete_button" onClick="return '+ instance_name +'.remove();"> \
              <i class="icon-remove"></i> Delete \
            </button> \
          </div> \
          <div class="span pull-right"> \
            <button class="btn btn-warning" data-dismiss="modal"><i class="icon-eject"></i> Close</button> \
            <button class="btn btn-success" onClick="'+ instance_name +'.save();"><i class="icon-file"></i> Save</button> \
          </div> \
        </div> \
      </div> \
    </div>');
  }
}
