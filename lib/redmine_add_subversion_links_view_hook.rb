# coding: UTF-8

class AddSubversionLinksViewHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(content)
    css = <<"EOS"
<style type="text/css">
body.controller-repositories table.changesets tr.changeset td.id{
  white-space: nowrap;
}
</style>
EOS
    return css
  end
end

