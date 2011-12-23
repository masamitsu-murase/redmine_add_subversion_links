# coding: UTF-8

require_dependency("application_helper")

module AddSubversionLinksApplicationHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethod)

    base.class_eval do
      alias_method_chain :parse_redmine_links, :add_subversion_links
      alias_method_chain :link_to_revision, :add_subversion_links

      # Note:
      # Redmine::Hook::ViewListener includes ApplicationHelper 
      # before this module is included by ApplicationHelper.
      # Therefore, ViewListener's ancestor includes ApplicationHelper 
      # but it does not includes this module.
      # The following alias_method enables us to call link_to_original_subversion_repository
      # in hook functions.
      alias_method :link_to_original_subversion_repository, :def_link_to_original_subversion_repository
    end
  end

  module InstanceMethod
    # refer to application_helper.rb
    # Regular expression is as same as the one defined in parse_redmine_links.
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
            # format_revision is defined in repositories_helper,
            # so it cannot be called in issues page.
            next m + " " + link_to_original_subversion_repository(project.repository.url, rev)
          end
        end
        next m
      end

      parse_redmine_links_without_add_subversion_links(text, project_org, obj, attr, only_path, options)
    end

    def link_to_revision_with_add_subversion_links(revision, project, options={})
      link = link_to_revision_without_add_subversion_links(revision, project, options)
      if (revision && project && 
          project.repository && project.repository.scm_name == "Subversion")
        rev = revision.respond_to?(:identifier) ? revision.identifier : revision
        link += " " + link_to_original_subversion_repository(project.repository.url, rev)
      end
      return link
    end

    def def_link_to_original_subversion_repository(url, rev)
      # Note:
      # url_for is called in link_to method.
      # Rails has two url_for methods, one is in url_helper.rb and the other is in url_rewriter.rb.
      # url_for in url_helper.rb can accept raw URL address,
      # but url_for in url_rewriter.rb cannot.
      # Therefore, I use content_tag instead of link_to method.
      return content_tag(:a, image_tag("svn_icon.png",
                                       :plugin => "redmine_add_subversion_links",
                                       :class => "add_subversion_links_icon"),
                         :href => url + "?p=#{rev}",
                         :rel => "tsvn[log][#{rev},#{rev}]",
                         :class => "add_subversion_links_link",
                         :title => l(:label_redmine_add_subversion_links_link_to_svn_repository,
                                     rev.to_s))
    end
  end
end

ApplicationHelper.send(:include, AddSubversionLinksApplicationHelperPatch)

