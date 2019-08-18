# -*- coding: utf-8 -*-

require_dependency("application_helper")
require_relative("redmine_add_subversion_links_settings")

module AddSubversionLinksApplicationHelperPatch
  # refer to application_helper.rb
  # Regular expression is as same as the one defined in parse_redmine_links.
  def parse_redmine_links(text, default_project, obj, attr, only_path, options)
    text.gsub!(ApplicationHelper::LINKS_RE) do |m|
      tag_content = $~[:tag_content]
      leading = $~[:leading]
      esc = $~[:esc]
      project_prefix = $~[:project_prefix]
      project_identifier = $~[:project_identifier]
      prefix = $~[:prefix]
      repo_prefix = $~[:repo_prefix]
      repo_identifier = $~[:repo_identifier]
      sep = $~[:sep1] || $~[:sep2] || $~[:sep3] || $~[:sep4]
      identifier = $~[:identifier1] || $~[:identifier2] || $~[:identifier3]
      comment_suffix = $~[:comment_suffix]
      comment_id = $~[:comment_id]

      next m if tag_content

      begin
        project = default_project
        if project_identifier
          project = Project.visible.find_by_identifier(project_identifier)
        end
        if esc.nil?
          if prefix.nil? && sep == 'r'
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
        elsif sep == ':'
          name = remove_double_quotes(identifier)
          if prefix == 'source'
            if project
              repository = nil
              if name =~ %r{^(([a-z0-9\-_]+)\|)(.+)$}
                repo_prefix, repo_identifier, name = $1, $2, $3
                repository = project.repositories.detect {|repo| repo.identifier == repo_identifier}
              else
                repository = project.repository
              end
              if repository && repository.scm_name == 'Subversion' &&
                  User.current.allowed_to?(:browse_repository, project)
                name =~ %r{^[/\\]*(.*?)(@([^/\\@]+?))?(#(L\d+))?$}
                path, rev, anchor = $1, $3, $5
                url = repository.url.sub(/\/$/, "") + "/#{to_path_param(path)}"
                next m + " " + link_to_original_subversion_repository(url, rev)
              end
            end
          end
        end
      rescue
      end
      next m
    end

    super(text, default_project, obj, attr, only_path, options)
  end

  def link_to_revision(revision, repository, options={})
    link = super(revision, repository, options)

    if (repository.is_a?(Project))
      repository = repository.repository
    end
    if (revision && repository && repository.scm_name == "Subversion" &&
        User.current.allowed_to?(:browse_repository, repository.project))
      rev = revision.respond_to?(:identifier) ? revision.identifier : revision
      if (controller_name == "issues")
        changeset = Changeset.visible.find_by_repository_id_and_revision(repository.id, rev)
        url = add_subversion_links_root_url_of_changesets(repository, changeset)
      else
        url = repository.url
      end
      link += " ".html_safe + link_to_original_subversion_repository(url, rev)
    end
    return link
  end

  def add_subversion_links_root_url_of_changesets(repository, changeset)
    path_str = ""
    unless AddSubversionLinksSettings.static_root_path_for_svn_link?
      begin
        if changeset && !(changeset.filechanges.all?{ |fc| fc.action == "D" })
          filechanges = changeset.filechanges
          if filechanges.size > 0
            path = repository.relative_path(filechanges.first.path).split("/")
            filechanges.drop(1).each do |fc|
              path = path.zip(repository.relative_path(fc.path).split("/")).take_while{ |a,b| a==b }.map(&:first)
            end
            path_str = path.join("/")
            path_str = "/" + path_str if (path_str[0] && path_str[0] != "/")
          end
        end
      rescue
        path_str = ""
      end
    end

    return repository.url.sub(/\/$/, "") + path_str
  end

  def link_to_original_subversion_repository(url, rev)
    # Note:
    # url_for is called in link_to method.
    # Rails has two url_for methods, one is in url_helper.rb and the other is in url_rewriter.rb.
    # url_for in url_helper.rb can accept raw URL address,
    # but url_for in url_rewriter.rb cannot.
    # Therefore, I use content_tag instead of link_to method.
    param = {
      :href => url,
      :"data-tsvn-info" => "tsvn[log]",
      :class => "add_subversion_links_link",
      :title => l(:label_redmine_add_subversion_links_link_to_svn_repository)
    }
    if (rev && !(rev.blank?))
      param[:href] += "?p=#{rev}"
      param[:"data-tsvn-info"] += "[#{rev},#{rev}]"
      param[:title] = l(:label_redmine_add_subversion_links_link_to_svn_repository_with_revision, rev)
    end
    return content_tag(:a, image_tag("svn_icon.png",
                                      :plugin => "redmine_add_subversion_links",
                                      :class => "add_subversion_links_icon"),
                    param)
  end
end

ApplicationHelper.prepend(AddSubversionLinksApplicationHelperPatch)