# coding: UTF-8

require_dependency("application_helper")

module OpenTortoiseSvnWikiPatch
  def self.included(base)
    base.send(:include, InstanceMethod)

    base.class_eval do
      alias_method_chain :parse_redmine_links, :open_tortoise_svn_link
    end
  end

  module InstanceMethod
    # refer to application_helper.rb
    def parse_redmine_links_with_open_tortoise_svn_link(text, project, obj, attr, only_path, options)
      text.gsub!(%r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-]+):)?(attachment|document|version|commit|source|export|message|project)?((#|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}) do |m|
        leading, esc, project_prefix, project_identifier, prefix, sep, identifier = $1, $2, $3, $4, $5, $7 || $9, $8 || $10
        link = nil
        if project_identifier
          project = Project.visible.find_by_identifier(project_identifier)
        end
        if esc.nil?
          if prefix.nil? && sep == 'r'
            # project.changesets.visible raises an SQL error because of a double join on repositories
            if project && project.repository && project.repository.scm_name == "Subversion" &&
                (changeset = Changeset.visible.find_by_repository_id_and_revision(project.repository.id, identifier))
              next m + " " + link_to("HOGE", project.repository.url, :rel => "tsvn[log][#{changeset.revision},#{changeset.revision}]")
            end
          end
        end
        next m
      end

      parse_redmine_links_without_open_tortoise_svn_link(text, project, obj, attr, only_path, options)
    end
  end
end

ApplicationHelper.send(:include, OpenTortoiseSvnWikiPatch)

