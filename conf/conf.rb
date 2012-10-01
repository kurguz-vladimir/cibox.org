class Cfg
  class << self

    def root
      @root ||= ::File.expand_path('../../..', __FILE__) << '/'
    end

    def app_path
      Cfg.root / 'app/'
    end

    %w[public var tmp].each do |m|
      define_method '%s_path' % m do
        Cfg.root / m << '/'
      end
    end

    %w[model view ctrl helper spec].each do |m|
      define_method '%s_path' % m do
        Cfg.app_path / m << '/'
      end
    end

    def set_env
      @env = ::File.directory?('/somebit') ? :dev : :prod
      @dev = @env == :dev
      @prod = @env == :prod
    end

    def env
      @env
    end

    def dev?
      @dev
    end

    def prod?
      @prod
    end

    def raw_config
      @raw_config ||= YAML.load(File.read(Cfg.app_path / 'conf/conf.yml')).freeze
    end

    def credentials
      @credentials ||= YAML.load(File.read(Cfg.app_path / 'conf/credentials.yml')).freeze
    end
    
  end
  
  self.set_env

  class << self
    Cfg.raw_config.select { |e, v| e == Cfg.env && v }.each_value do |opts|
      opts.each_pair do |var, val|
        define_method var do
          instance_variable_get('@%s' % var) || instance_variable_set('@%s' % var, val.freeze)
        end
      end
    end
  end
end
