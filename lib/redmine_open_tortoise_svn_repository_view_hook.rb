# coding: UTF-8

module OpenTortoiseSvnHooks
  class OpenTortoiseSvnHooksViewListener < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      ctrl = context[:controller]
      return "" unless (ctrl && ctrl.controller_name == "repositories" &&
                        ctrl.instance_variable_defined?(:@project) &&
                        ctrl.instance_variable_defined?(:@repository) &&
                        ctrl.instance_variable_get(:@repository).scm_name == "Subversion")

      return context[:controller].send(:render_to_string, {
                                         :partial => "open_tortoise_svn/repository_index"
                                       })
    end
  end
end

