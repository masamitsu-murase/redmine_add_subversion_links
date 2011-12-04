# coding: UTF-8

class AddSubversionLinksViewHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(content)
    # Show the original link and the icon for Subversion in a single line.
    css = <<"EOS"
<style type="text/css">
body.controller-repositories table.changesets tr.changeset td.id{
  white-space: nowrap;
}
img.add_subversion_links_icon{
  vertical-align: middle;
}
</style>
EOS
    return css
  end
end

