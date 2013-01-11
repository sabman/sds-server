if File.exist?("#{Rails.root}/config/app_config.yml")
    config_file = YAML.load_file("#{Rails.root}/config/app_config.yml")
    APP_CONFIG = config_file[Rails.env].symbolize_keys
  else
    APP_CONFIG = {}
  end
