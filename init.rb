require 'redmine'
require "redmine_add_subversion_links_application_helper_patch"
require "redmine_add_subversion_links_view_hook"

Redmine::Plugin.register :redmine_add_subversion_links do
  name 'Redmine Add Subversion Links'
  author 'Masamitsu MURASE'
  description 'This is a plugin for Redmine to add Subversion links to the repository.'
  version '0.5.0'
  url 'https://github.com/masamitsu-murase/redmine_add_subversion_links'
  author_url 'http://masamitsu-murase.blogspot.jp'
end
