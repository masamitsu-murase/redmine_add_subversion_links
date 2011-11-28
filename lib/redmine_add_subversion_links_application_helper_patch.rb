# coding: UTF-8

require_dependency("application_helper")

module AddSubversionLinksApplicationHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethod)

    base.class_eval do
      alias_method_chain :parse_redmine_links, :add_subversion_links
    end
  end

  module InstanceMethod
    # refer to application_helper.rb
    def parse_redmine_links_with_add_subversion_links(text, project, obj, attr, only_path, options)
      project_org = project
      text.gsub!(%r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-]+):)?(attachment|document|version|commit|source|export|message|project)?((#|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}) do |m|
        leading, esc, project_prefix, project_identifier, prefix, sep, identifier = $1, $2, $3, $4, $5, $7 || $9, $8 || $10
        if project_identifier
          project = Project.visible.find_by_identifier(project_identifier)
        end
        if esc.nil? && prefix.nil? && sep == 'r'
          # project.changesets.visible raises an SQL error because of a double join on repositories
          if project && project.repository && project.repository.scm_name == "Subversion" &&
              (changeset = Changeset.visible.find_by_repository_id_and_revision(project.repository.id, identifier))
            rev = changeset.revision
            next m + " " + link_to(image_tag("svn_icon.png", :plugin => "redmine_add_subversion_links"),
                                   project.repository.url, :rel => "tsvn[log][#{rev},#{rev}]")
          end
        end
        next m
      end

      parse_redmine_links_without_add_subversion_links(text, project_org, obj, attr, only_path, options)
    end
  end
end

ApplicationHelper.send(:include, AddSubversionLinksApplicationHelperPatch)

