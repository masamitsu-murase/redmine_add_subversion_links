# coding: UTF-8

module OpenTortoiseSvnHooks
  class OpenTortoiseSvnHooksViewListener < Redmine::Hook::ViewListener
    def view_repositories_show_contextual(context)
      return "<h3><strong>Open TortoiseSVN test</strong></h3>"
    end
  end
end

