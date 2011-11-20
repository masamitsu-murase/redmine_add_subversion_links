
// Current version of redmine uses Rails 2.3.x, so we can use prototype.js.
(function(){
    if (!gOpenTortoiseSvn || !gOpenTortoiseSvn.valid){
        return;
    }

    var TABLE_CLASS_NAME = "open_tortoise_svn";
    var TSVN_ATTRIBUTE_NAME = "rel";  // for HTML4.01
    var REPOSITORY_URL = gOpenTortoiseSvn.repository_url;
    var SVN_IMAGE_PATH = gOpenTortoiseSvn.svn_image_path;

    var load = function(){
        addLinksToRepository();
        addLinkToCompare();
    };

    var addLinksToRepository = function(){
        var tables = $$("table.changesets");
        if (tables.length != 1){
            return;
        }

        var table = tables[0];
        if (table.hasClassName(TABLE_CLASS_NAME)){
            return;
        }
        table.addClassName(TABLE_CLASS_NAME);

        table.select("tr.changeset td.id").each(function(elem){
            var rev = parseInt(elem.firstChild.innerHTML, 10);
            elem.appendChild(createTortoiseSvnLinkTag(REPOSITORY_URL,
                                                      "log", [ rev, rev ]));
        });
    };

    var addLinkToCompare = function(){
        var forms = $$("form").findAll(function(f){
            return f.select("table.changesets").length == 1;
        });
        if (forms.length != 1){
            return;
        }

        var form = forms[0];
        var log_elem = createTortoiseSvnLinkTag(REPOSITORY_URL, null, null, "HOGE Compare");
        form.appendChild(log_elem);

        var rev_items = form.select("td.checkbox input[name='rev']");
        var rev_to_items = form.select("td.checkbox input[name='rev_to']");
        var set_log_elem_attr = function(event){
           // Set rel attribute to pass selected revision to Open TortoiseSVN addon.
            var rev = rev_items.find(function(elem){ return elem.checked; });
            var rev_to = rev_to_items.find(function(elem){ return elem.checked; });
            if (!rev || !rev_to){
                return;
            }
            log_elem.setAttribute(TSVN_ATTRIBUTE_NAME, tsvnAttribute("log", [ rev.value, rev_to.value ]));
        };
        rev_items.each(function(item){ item.observe("change", set_log_elem_attr); });
        rev_to_items.each(function(item){ item.observe("change", set_log_elem_attr); });

        set_log_elem_attr(null);
    };

    var createTortoiseSvnLinkTag = function(url, action, args, content){
        var elem = document.createElement("a");
        elem.setAttribute("href", url);
        if (action){
            elem.setAttribute(TSVN_ATTRIBUTE_NAME, tsvnAttribute(action, args));
        }
        if (typeof content == "string"){
            content = document.createTextNode(content);
        }else if (!content){
            var img = document.createElement("img");
            img.setAttribute("src", SVN_IMAGE_PATH);
            img.setAttribute("alt", "Subversion " + action);
            content = img;
        }
        elem.appendChild(content);
        return elem;
    };

    var tsvnAttribute = function(action, args){
        if (typeof args == "array"){
            args = "[" + args.join(",") + "]";
        }else if (args){
            args = "[" + args + "]";
        }else{
            args = "";
        }

        return "tsvn[" + action + "]" + args;
    };

    Element.observe(window, "load", load);
})();
