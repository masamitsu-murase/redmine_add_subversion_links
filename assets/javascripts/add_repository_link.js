
var gAddSubversionLinksFuncs = (function(){
    var $ = jQuery;

    // "onload" should be called only when Subversion repository page is shown.
    var onload = function(info){
        if (info.action == "show"){
            addRepositoryLinkInRepositoryPage(info, $("table#browser tbody tr > td.filename:first-child a.icon"));
            // To update Ajax elements
            addAjaxEventHandler(info);
        }else if (info.action == "revision"){
            addRepositoryLinkInRepositoryPage(info, $("div.changeset-changes li.change a:first-child"));
        }
    };

    var parseScmUrl = function(url){
        // This pattern depends on the parameter structure of "repository controller".
        var scm_url_pattern = new RegExp("/projects/[^/]+/repository/([_a-z0-9\\-]+/)?(revisions/([0-9]+)/)?(changes|show|entry)/([^#&?]*)(\\?[^#]+)?");

        if (!url){
            return null;
        }

        var match_data = url.match(scm_url_pattern);
        if (!match_data){
            return null;
        }

        var obj = {
            path: match_data[5]
        };
        if (match_data[2] && match_data[3]){
            obj.revision = match_data[3];
        }

        var param_str = match_data[6];
        if (param_str){
            match_data = param_str.match(/parent_id=([0-9a-f]+)/);
            if (match_data){
                obj.parent_id = match_data[1];
            }
            match_data = param_str.match(/rev=([0-9]+)/);
            if (match_data){
                obj.revision = match_data[1];
            }
        }

        return obj;
    };

    var addRepositoryLinkInRepositoryPage = function(info, links){
        links.each(function(){
            var link = this;

            var href = link.getAttribute("href");
            if (!href){
                return;
            }

            var scm_info = parseScmUrl(href);
            if (!scm_info){
                return;
            }

            var repos_link_elem = createRepositoryLinkElement(info, scm_info.path, scm_info.revision);
            $(link).after(repos_link_elem);
        });
    };

    var addAjaxEventHandler = function(info){
        // This function depends on application.js.
        $("#browser").ajaxSuccess(function(e, xhr, option){
            var url = option.url;
            if (typeof(url) != "string" || !url){
                return;
            }

            var scm_info = parseScmUrl(url);
            if (!scm_info || !(scm_info.parent_id)){
                return;
            }

            var condition = "#browser tbody tr." + scm_info.parent_id + " > td.filename:first-child a.icon";
            addRepositoryLinkInRepositoryPage(info, $(condition));
        });
    };

    var createRepositoryLinkElement = function(info, path, revision){
        var param = {
            href: info.svn_root_url + "/" + path,
            "class": "add_subversion_links_link",
            rel: "tsvn[log]"
        };
        if (revision){
            param.rel += "[" + revision + "," + revision + "]";
            param.href += "?" + $.param({ p: revision });
        }
        var elem = $("<a />");
        elem.html(info.svn_icon_image_tag);
        for (var key in param){
            elem.attr(key, param[key]);
        }
        return elem.get(0);
    };

    return {
        onload: onload
    };
})();

