# -*- coding: utf-8 -*-

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
      text.gsub!(%r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(attachment|document|version|forum|news|message|project|commit|source|export)?(((#)|((([a-z0-9\-_]+)\|)?(r)))((\d+)((#note)?-(\d+))?)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]][^A-Za-z0-9_/])|,|\s|\]|<|$)}) do |m|
        leading, esc, project_prefix, project_identifier, prefix, repo_prefix, repo_identifier, sep, identifier, comment_suffix, comment_id = $1, $2, $3, $4, $5, $10, $11, $8 || $12 || $18, $14 || $19, $15, $17
        link = nil
        if project_identifier
          project = Project.visible.find_by_identifier(project_identifier)
        end
        if esc.nil? && prefix.nil? && sep == 'r'
          if project
            repository = nil
            if repo_identifier
              repository = project.repositories.detect {|repo| repo.identifier == repo_identifier}
            else
              repository = project.repository
            end
            # project.changesets.visible raises an SQL error because of a double join on repositories
            if repository && repository.scm_name == "Subversion" &&
                (changeset = Changeset.visible.find_by_repository_id_and_revision(repository.id, identifier))
              rev = changeset.revision
              url = add_subversion_links_root_url_of_changesets(repository, changeset)
              next m  + " " + link_to_original_subversion_repository(url, rev)
            end
          end
        end
        next m
      end

      parse_redmine_links_without_add_subversion_links(text, project_org, obj, attr, only_path, options)
    end

    def link_to_revision_with_add_subversion_links(revision, repository, options={})
      link = link_to_revision_without_add_subversion_links(revision, repository, options)

      if (repository.is_a?(Project))
        repository = repository.repository
      end
      if (revision && repository && repository.scm_name == "Subversion" &&
          User.current.allowed_to?(:browse_repository, repository.project))
        rev = revision.respond_to?(:identifier) ? revision.identifier : revision
        changeset = Changeset.visible.find_by_repository_id_and_revision(repository.id, rev)
        url = add_subversion_links_root_url_of_changesets(repository, changeset)
        link += " ".html_safe + link_to_original_subversion_repository(url, rev)
      end
      return link
    end

    def add_subversion_links_root_url_of_changesets(repository, changeset)
      path_str = ""
      begin
        if (changeset)
          filechanges = changeset.filechanges
          if (filechanges && filechanges.size > 0)
            path = repository.relative_path(filechanges.first.path).split("/")
            filechanges.drop(1).each do |fc|
              path = path.zip(repository.relative_path(fc.path).split("/")).take_while{ |a,b| a==b }.map(&:first)
            end
            path_str = path.join("/")
          end
        end
      rescue
        path_str = ""
      end

      return repository.url + path_str
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

