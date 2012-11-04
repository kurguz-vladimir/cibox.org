MIMEMap = function () {

  var c_cpp_mode       = 'c_cpp';
  var clojure_mode     = 'clojure';
  var coffee_mode      = 'coffee';
  var coldfusion_mode  = 'coldfusion';
  var csharp_mode      = 'csharp';
  var css_mode         = 'css';
  var diff_mode        = 'diff';
  var golang_mode      = 'golang';
  var groovy_mode      = 'groovy';
  var haxe_mode        = 'haxe';
  var html_mode        = 'html';
  var java_mode        = 'java';
  var javascript_mode  = 'javascript';
  var json_mode        = 'json';
  var jsx_mode         = 'jsx';
  var latex_mode       = 'latex';
  var less_mode        = 'less';
  var liquid_mode      = 'liquid';
  var lua_mode         = 'lua';
  var markdown_mode    = 'markdown';
  var perl_mode        = 'perl';
  var pgsql_mode       = 'pgsql';
  var php_mode         = 'php';
  var powershell_mode  = 'powershell';
  var python_mode      = 'python';
  var ruby_mode        = 'ruby';
  var scala_mode       = 'scala';
  var scss_mode        = 'scss';
  var sh_mode          = 'sh';
  var sql_mode         = 'sql';
  var svg_mode         = 'svg';
  var tcl_mode         = 'tcl';
  var text_mode        = 'text';
  var textile_mode     = 'textile';
  var xml_mode         = 'xml';
  var xquery_mode      = 'xquery';
  var yaml_mode        = 'yaml';

  this.editor_map = {
    c:            c_cpp_mode,
    cpp:          c_cpp_mode,
    h:            c_cpp_mode,
    clj:          clojure_mode,
    coffee:       coffee_mode,
    cfc:          coldfusion_mode,
    cfm:          coldfusion_mode,
    cfml:         coldfusion_mode,
    cs:           csharp_mode,
    css:          css_mode,
    sass:         css_mode,
    diff:         diff_mode,
    go:           golang_mode,
    groovy:       groovy_mode,
    hx:           haxe_mode,
    htm:          html_mode,
    html:         html_mode,
    erb:          ruby_mode,
    erubis:       ruby_mode,
    xhtml:        html_mode,
    
    'java':         java_mode,
    jsp:          java_mode,
    jspx:         java_mode,
    wss:          java_mode,
    'do':           java_mode,
    action:       java_mode,

    js:           javascript_mode,
    json:         json_mode,
    jsx:          jsx_mode,
    tex:          latex_mode,
    less:         less_mode,
    liquid:       liquid_mode,
    lua:          lua_mode,
    
    md:           markdown_mode,
    mkd:          markdown_mode,
    markdown:     markdown_mode,
    
    pl:           perl_mode,
    pm:           perl_mode,
    t:            perl_mode,
    
    pgsql:        pgsql_mode,
    
    php:          php_mode,
    phps:         php_mode,
    php3:         php_mode,
    php4:         php_mode,
    phtml:        php_mode,

    ps1:          powershell_mode,   
    ps1xml:       powershell_mode,
    psc1:         powershell_mode,  
    psd1:         powershell_mode,  
    psm1:         powershell_mode,
    py:           python_mode,
    pyw:          python_mode,
    pyc:          python_mode,
    pyo:          python_mode,
    pyd:          python_mode,
    rb:           ruby_mode,
    ru:           ruby_mode,
    rakefile:     ruby_mode,
    gemfile:      ruby_mode,
    gemspec:      ruby_mode,
    scala:        scala_mode,
    scss:         scss_mode,
    sh:           sh_mode,
    bash:         sh_mode,
    csh:          sh_mode,
    tcsh:         sh_mode,
    zsh:          sh_mode,
    sql:          sql_mode,
    svg:          svg_mode,
    tcl:          tcl_mode,
    txt:          text_mode,
    textile:      textile_mode,
    atom:         xml_mode,
    atomcat:      xml_mode,
    atomsvc:      xml_mode,
    ccxml:        xml_mode,
    cdxml:        xml_mode,
    dtd:          xml_mode,
    mml:          xml_mode,
    mxml:         xml_mode,
    rsd:          xml_mode,
    rss:          xml_mode,
    xsl:          xml_mode,
    xslt:         xml_mode,
    xsm:          xml_mode,
    xq:           xquery_mode,
    xqy:          xquery_mode,
    xquery:       xquery_mode,
    yaml:         yaml_mode,
    yml:          yaml_mode
  }

  var node_mode = 'node';
  var typescript_mode = 'typescript';
  this.ui_map = {};
  for (var k in this.editor_map)
    this.ui_map[k] = this.editor_map[k];
  this.ui_map['js'] = node_mode;
  this.ui_map['ts'] = typescript_mode;

}
