DataMapper.setup :default, 'sqlite3://' / Cfg.var_path / 'db' / "#{Cfg.env}.db"
