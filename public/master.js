function generateUUID(){
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c=='x' ? r : (r&0x7|0x8)).toString(16);
    });
    return uuid;
}

function getQueryString() {
  var result = {}, queryString = location.search.substring(1),
      re = /([^&=]+)=([^&]*)/g, m;

  while (m = re.exec(queryString)) {
    result[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
  }

  return result;
}

CIBox = function(user, repo, path){

  CLASS_DATA = {};
  var class_data = jQuery.extend(true, {}, CIBox.CLASS_DATA);
  var mime = new MIMEMap();
  
  this.url_map = {}

  this.login = function(url) {
    $.post(url, class_data);
  }

  this.update_repo_list = function (url) {
    $.get(
      [url, user, repo].join('/'),
      jQuery.extend(true, {}, class_data, {path: path}),
      function (response) { 
        $('#repos').html(response);
        $('.dropdown-toggle').dropdown();
      }
    );
  }

  this.update_procedures_list = function (url) {
    $.get(
      url + '/' + user,
      class_data,
      function (response) { 
        $('#procedures').html(response);
        $('.dropdown-toggle').dropdown();
      }
    );
  }

  this.invoke_procedure = function (url, procedure_id) {
    $('#shell-output').addClass("shell-output");
    $('#shell-prompt').focus();
        
    $.ajax({
      url:  url,
      // do not use POST here cause this will break autorun on Mozilla browsers
      type: 'GET',
      data: jQuery.extend(true, {}, class_data, {
        repo: repo,
        lang: cibox.effective_lang(), 
        versions: cibox.effective_lang_versions(),
        path: path,
        procedure_id: procedure_id
      }),
      complete: function (xhr, status) {
        if (status == 'success') return true;
        cibox.error("<h4>Some error occurred</h4>\
          Please reload the page.<br/>\
          If it does not help, make sure you are using a browser that supports Server-Sent Events.<br/>\
          If your browser is ok, please report this issue via #cibox IRC channel on irc.freenode.net<br/>\
          Thank you");
      }
    });
  }

  this.invoke_file_reader = function(url, file, update_location) {
    var cibox = this;
    $.post(
      [url, user, repo].join('/'),
      jQuery.extend(true, {}, class_data, {path: path, file: file}),
      function(response) {

        cibox.effective_file(file);

        var file_ext = cibox.effective_file_ext(file);
        cibox.is_compilable(cibox.effective_lang(), file_ext);

        var editor = ace.edit("file_reader-content");
        var editor_session = editor.getSession();
        editor_session.setValue(response);
        editor_session.setMode("ace/mode/" + (mime.editor_map[file_ext] || 'text'));
        editor.focus();
        $('#file_reader').show();

        if( update_location == undefined || update_location == true )
          cibox.update_location.extend({file: file}, ['run', 'procedure_id']);
        
      }
    );
  }

  this.invoke_file_runner = function (file, update_location) {
    var file = file || this.effective_file();
    $('#shell-output').addClass('shell-output');
    // do not use POST here cause this will break autorun on Mozilla browsers
    $.get(
      this.url_map.run_file,
      jQuery.extend(true, {}, class_data, {
        user: user,
        repo: repo,
        path: path,
        file: file,
        lang: cibox.effective_lang(),
        versions: cibox.effective_lang_versions()
      }),
      function () {
        if( update_location == undefined || update_location == true )
          cibox.update_location.extend({file: file, run: true}, ['procedure_id']);
      }
    );
  }

  this.save_file = function (url, after_save) {
    var editor = ace.edit("file_reader-content");
    var data = jQuery.extend(true, {}, class_data, {
      user: user,
      repo: repo,
      path: path,
      file: this.effective_file(),
      content: editor.getSession().getValue(),
      // lang and versions needed to run/compile file after saving it, if requested
      lang: cibox.effective_lang(),
      versions: cibox.effective_lang_versions()
    });
    if (after_save) {
      data['after_save'] = after_save;
      if (after_save == 'run' || after_save == 'compile') 
        $('#shell-output').addClass('shell-output');
    }
    $.post(url, data);
  }

  this.invoke_shell = function(url) {
    var cmd  = $.trim( $('#shell-prompt').val() || '' );
    if( cmd.length == 0 ) return false;

    if( shell_history.slice().pop() != cmd )
      shell_history.push(cmd);
    shell_history_index = shell_history.length;
    $('#shell-prompt').val(null);
    $('#shell-output').addClass("shell-output");
    $('#shell-output').append("<strong>$ " + cibox.sanitize_output(cmd) + "</strong><br/>");
    cibox.scroll_shell();
    
    $.ajax({
      url: url,
      type: 'POST',
      data: jQuery.extend(true, {}, class_data, {
        repo: repo,
        path: path,
        lang: cibox.effective_lang(),
        versions: cibox.effective_lang_versions(),
        cmd: cmd
      }),
      complete: function(xhr, status) {
        if (xhr.status == 401) {
          $('#shell-output').append("=== Please Login ===<br/>");
        } else {
          if(status == 'success') return true;
          cibox.error("Please reload the page. If it does not help, \
            make sure you are using a browser that supports Server-Sent Events.");
        }
      }
    });
    
  }

  this.remove_ssh_key = function(url, key){
    if(confirm('Removing key?')){ 
      $.ajax({
        url:  url,
        type: 'DELETE',
        data: jQuery.extend(true, {}, class_data, {key: key})
      }) 
    }
  }

  this.fork_repo = function(url) {
    $.post(url, class_data);
  }

  this.download_repo = function(url) {
    $.get(url, class_data);
  }

  this.reset_shell_output = function () {
    $('#shell-output').html(null).removeClass('shell-output');
    $('.errors-row').remove();
    $('#shell-prompt').focus();
  }

  this.update_repo_fs = function (url) {
    $.ajax({
      url:  [url, user, repo].join('/'),
      type: 'GET',
      data: jQuery.extend(true, {}, class_data, {path: path}),
      datatype: "html",
      complete: function (xhr) {
        if(xhr.status == 404) {
          cibox.error('Repo Not Found');
        } else {
          $('#repo_fs-fm').html(xhr.responseText);

          $('.fm-file').each(function () {
            var lcext = $(this).attr('lcext');
            $(this).addClass('fm-' + (mime.ui_map[lcext] || 'text') + '_file');
          });
        }
      }
    });
  }

  this.switch_lang = function (lang, ext) {
    $('#effective-lang').val(lang);
    $('#menu-tab a[lang="'+ lang +'"]').tab('show');
    if(ext) this.is_compilable(lang, ext);
  }

  this.effective_lang = function () {
    return $('#effective-lang').val();
  }

  this.effective_lang_versions = function (read_from_verselector) {
    if(read_from_verselector) {
      var selected = $('#verselector-' + this.effective_lang()).val() || [];
      if(selected.length > 0) return selected.join('+');
      return '*';
    }
    var queryString = getQueryString();
    return queryString['versions'] || '';
  }

  this.effective_file = function (file) {
    return file ? 
      $('#file_reader-name').text(file) :
      $('#file_reader-name').text();
  }
  this.effective_file_ext = function (file) {
    if (file == undefined)
      file = this.effective_file();
    if (file)
      return file.split('.').pop().toLowerCase();
  }

  this.is_compilable = function (lang, ext) {
    var compilable = (lang == 'Node' && (ext == 'coffee' || ext == 'ts'));
    if (compilable) {
      $('.file_reader-compile').show();
      $('.file_reader-run').hide();
    } else {
      $('.file_reader-compile').hide();
      $('.file_reader-run').show();
    }
    return compilable;
  }

  this.scroll_shell = function () {
    $('#shell-output').animate({scrollTop: $('#shell-output')[0].scrollHeight}, 0);
  }

  this.sanitize_output = function(str) {
    if(!str) return '';
    return str.replace(/[^\w|\d|\n|\s|.|-]/g, function (chr) {
      return '&#' + chr.charCodeAt(0) + ';'; 
    });
  }

  this.show_progress_bar = function () {
    $('#progress_bar').show();
  }
  this.hide_progress_bar = function () {
    $('#progress_bar').hide();
  }

  addressBar = function (updateLocation) {

    this.set = function(data) {
      var queryString = decodeURIComponent(jQuery.param(data));
      var url = window.location.pathname + '?' + queryString;
      if(updateLocation)
        window.history.pushState(data, queryString, url)
      else
        return url;
    }

    this.extend = function (data, remove_keys) {
      var queryString = getQueryString();
      if (remove_keys) {
        for(key in remove_keys)
          delete(queryString[remove_keys[key]]);
      }
      return this.set(jQuery.extend({}, queryString, data));
    }

    this.remove = function (keys) {
      var queryString = getQueryString();
      for(key in keys)
        delete(queryString[keys[key]]);
      return this.set(queryString);
    }

    this.clear = function() {
      return this.set('');
    }
  }
  this.update_location = new addressBar(true);
  this.get_location = new addressBar();

  this.alert = function(alert) {
    $('.top-right').notify({
      type: 'success',
      message: { html: alert },
      fadeOut: { enabled: true, delay: 3000 }
    }).show();
  }

  this.error = function(error) {
    $('.top-right').notify({
      type: 'error',
      message: { html: '<pre class="alert alert-error" id="notifications-error">' + error + '</pre>' },
      fadeOut: { enabled: false }
    }).show();
  }
}

$(function(){

  if(window.name.length == 0)
    window.name = generateUUID();

  ECrudifyBootstrap.CLASS_DATA = {__stream_uuid__: window.name};
  CIBox.CLASS_DATA = {__stream_uuid__: window.name};

  shell_history = new Array();
  shell_history_index = 0;

  var ctrl_down = false;
  var ctrl_key = 17;

  $('#shell-prompt').keydown(function(e) {
      if (e.keyCode == ctrl_key) ctrl_down = true;
  }).keyup(function(e) {
      if (e.keyCode == ctrl_key) ctrl_down = false;
  });

  $('#shell-prompt').keydown(function(e) {
    if (ctrl_down) {
      if(e.keyCode == 76)
        cibox.reset_shell_output();
      if(e.keyCode == 85){
        $('#shell-prompt').val(null);
        shell_history.splice(shell_history_index, 1);
        shell_history_index -= 1;
      }
      return false;
    }
    if(e.keyCode == 9){
      var input = $('#shell-prompt').val();
      if (input.length > 1){
        var completions = [
          'ruby', 'gem', 'bundle', 'rake',
          'node', 'npm', 'coffee',
          'python', 'easy_install', 'pip',
          'php', 'pear', 'composer', 'phpunit'
        ];
        for (i=0; i < completions.length; i++){
          var completion = completions[i];
          if ( completion.match(new RegExp(input))) $('#shell-prompt').val(completion + " ");
        }
      }
      e.preventDefault();
    }
    if(e.keyCode == 38){
      shell_history_index -= 1;
      if(shell_history_index <= 0) shell_history_index = 0;
      $('#shell-prompt').val(shell_history[shell_history_index]);
      return false;
    }
    if(e.keyCode == 40){
      shell_history_index += 1;
      if(shell_history_index > shell_history.length) shell_history_index = shell_history.length;
      $('#shell-prompt').val(shell_history[shell_history_index]);
      return false;
    }
  });

});

