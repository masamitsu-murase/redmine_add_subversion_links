# -*- coding: utf-8 -*-

require "yaml"

module AddSubversionLinksSettings
  @@settings_data = YAML.load_file(File.expand_path("../config/settings.yml", __dir__))

  def self.static_root_path_for_svn_link?
    return @@settings_data["static_root_path_for_svn_link"]
  end
end
