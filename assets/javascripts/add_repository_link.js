
var gAddSubversionLinksFuncs = (function(){
    // "onload" should be called only when Subversion repository page is shown.
    var onload = function(info){
        if (info.action == "show"){
            addRepositoryLinkInRepositoryPage(info, $$("table#browser tbody tr > td.filename:first-child a.icon"));
            // To update Ajax elements
            patchScmEntryLoaded(info);
        }else if (info.action == "revision"){
            addRepositoryLinkInRepositoryPage(info, $$("div.changeset-changes li.change a:first-child"));
        }
    };

    var addRepositoryLinkInRepositoryPage = function(info, links){
        // This pattern depends on the parameter structure of "repository controller".
        var href_pattern = new RegExp("/projects/[^/]+/repository/(revisions/([0-9]+)/)?(changes|show|entry)/([^#&?]*)(\\?[^#]+)?");
        links.forEach(function(link){
            var href = link.getAttribute("href");
            if (!href){
                return;
            }

            var match_data = href.match(href_pattern);
            if (!match_data){
                return;
            }

            var path = match_data[4];
            var revision = null;
            if (match_data[1]){
                revision = match_data[2];
            }
            // var params = href.toQueryParams();
            var repos_link_elem = createRepositoryLinkElement(info, path, revision);
            link.parentNode.appendChild(repos_link_elem);
        });
    };

    var patchScmEntryLoaded = function(info){
        // This function depends on application.js.
        // If you would like to know the detail about function declaration of JavaScript,
        // please refer to https://developer.mozilla.org/en/JavaScript/Reference/Functions_and_function_scope#Function_constructor_vs._function_declaration_vs._function_expression.
        if (typeof(scmEntryLoaded) != "function"){
            return;
        }

        var scmEntryLoaded_without_add_subversion_links = scmEntryLoaded;
        scmEntryLoaded = function(id){
            var condition = "table#browser tbody tr." + id + " > td.filename:first-child a.icon";
            setTimeout(function(){ addRepositoryLinkInRepositoryPage(info, $$(condition)); }, 0);
            return scmEntryLoaded_without_add_subversion_links(id);
        };
    };

    var createRepositoryLinkElement = function(info, path, revision){
        var param = { href: info.svn_root_url + "/" + path, "class": "add_subversion_links_link" };
        if (revision){
            param.rel = "tsvn[browser][" + revision + "]";
            param.href += "?" + Object.toQueryString({ p: revision });
        }
        var elem = new Element("a", param);
        elem.update(new Element("img", {
            src: info.svn_icon_url, alt: "svn",
            "class": "add_subversion_links_icon"
        }));
        return elem;
    };

    return {
        onload: onload
    };
})();

