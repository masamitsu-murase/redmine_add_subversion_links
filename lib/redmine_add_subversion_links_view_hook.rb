# coding: UTF-8

class AddSubversionLinksViewHook < Redmine::Hook::ViewListener
  DEFAULT_CSS = <<"EOS"
<style type="text/css">
/* <![CDATA[ */
body.controller-repositories table.changesets tr.changeset td.id{
  white-space: nowrap;
}
a.add_subversion_links_link{
  margin-left: 0.25em !important;
  margin-right: 0.25em !important;
}
img.add_subversion_links_icon{
  vertical-align: middle;
}
/* ]]> */
</style>
EOS

  def view_layouts_base_html_head(context)
    # Show the original link and the icon for Subversion in a single line.
    css = DEFAULT_CSS
    proj = context[:project]
    ctrl = context[:controller]
    return css unless (proj && ctrl && ctrl.controller_name == "repositories" &&
      User.current.allowed_to?(:browse_repository, proj))

    repo_id = ctrl.params[:repository_id]
    if (repo_id)
      repos = proj.repositories.detect{ |repo| repo.identifier == repo_id }
    else
      repos = proj.repository
    end
    return css unless (repos && repos.scm_name == "Subversion")

    url = escape_javascript(repos.url.sub(/\/$/, ""))  # remove "/" suffix.
    icon_url = escape_javascript(image_path('svn_icon.png',
                                            :plugin => 'redmine_add_subversion_links'))
    js = <<"EOS"
Event.observe(window, "load", function(){
    var param = {
      svn_root_url: "#{url}",
      svn_icon_url: "#{icon_url}",
      action: "#{ctrl.action_name}"
    };
    if (typeof(gAddSubversionLinksFuncs) == "object" && gAddSubversionLinksFuncs.onload){
        gAddSubversionLinksFuncs.onload(param);
    }
});
EOS
    return css + javascript_tag(js) +
      javascript_include_tag("add_repository_link", :plugin => "redmine_add_subversion_links")
  end
end

