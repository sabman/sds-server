# tell the I18n library where to find your translations
I18n.load_path += Dir[Rails.root.join('lib', 'locale', '*.{rb,yml}')]

# set default locale to something other than :en
I18n.default_locale = :en

if Rails.env.development? || Rails.env.test?

  # raises exception when there is a wrong/no i18n key
  module I18n
    def self.raise_translation_exception(*args)
      raise "i18n #{args.first}"
    end
  end

  I18n.exception_handler = :raise_translation_exception

end