# coding: UTF-8

module OpenTortoiseSvnHooks
  class OpenTortoiseSvnHooksViewListener < Redmine::Hook::ViewListener
    def view_repositories_show_contextual(context)
      return "<h3><strong>Open TortoiseSVN test</strong></h3>" +
        context[:controller].send(:render_to_string, {
                                    :partial => "open_tortoise_svn/repository_index",
                                    :locals => {
                                      :project => context[:project],
                                      :repository => context[:repository]
                                    }
                                  })
    end
  end
end

