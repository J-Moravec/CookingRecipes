#!/bin/env Rscript
library("xfun", warn.conflicts = FALSE)
library("whisker")
library("rmarkdown")

tag = function(tag, content, ...){
    dots = list(...)
    if(length(dots) != 0){
        attributes = paste0(" ", names(dots), "=\"", dots, "\"", collapse = "")
        } else {
        attributes = character()
        }

    if(missing(content))
        return(paste0("<", tag, attributes, "/>"))

    if(length(content) == 1)
        return(paste0("<", tag, attributes, ">", content, "</", tag, ">"))

    c(
        paste0("<", tag, attributes, ">"),
        content,
        paste0("</", tag, ">")
        )
    }


tags = function(x, ...){
    .mapply(match.fun(tag), c("tag" = x, list(...)), NULL) |>
        unlist()
    }


yaml_front_matter = function(x){
    xfun::yaml_body(xfun::read_utf8(x), use_yaml = FALSE)$yaml
    }


interleave = function(...){
    c(do.call(rbind, list(...)))
    }


# Use internal http server to view site locally
# see: https://github.com/J-Moravec/serve
serve = function(dir = ".", port = 0, baseurl = NULL){
    httpd_static = function(path, query, ...){
        pattern = if(is.null(baseurl)) "^/" else sprintf("^/(%s/)?", baseurl)
        path = sub(pattern = pattern, replace = "", path)

        if(path == "") path = "index.html"
        if(file.exists(path) && file_test("-f", path)){
            list(file = path, "content-type" = xfun::mime_type(path))
            } else {
            list(payload = error404, "status code" = 404)
            }
        }

    error404 = paste0(
        "<!DOCTYPE html>",
        "<html lang=\"en\">",
        "<head>",
        "    <meta charset=\"UTF-8\">",
        "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
        "    <title>Resources not found</title>",
        "</head>",
        "<body>",
        "    <div class=\"main\">",
        "        <h1>404</h1>",
        "        <div>The page you are looking for is not found</div>",
        "        <a href=\"/\">Back to home</a>",
        "    </div>",
        "</body>",
        "</html>",
        collapse = "\n"
        )

    assign_in_namespace = function(x, f, envir){
        old = get(x, envir = envir)
        unlockBinding(x, envir)
        assign(x, f, envir = envir)
        lockBinding(x, envir)
        invisible(old)
        }

    stop_server = function(){
        port = tools:::httpdPort()
        if(port > 0)
            tools::startDynamicHelp(FALSE)
        }

    dir = normalizePath(dir)
    if(port) options(help.ports = port)

    old_httpd = assign_in_namespace("httpd", httpd_static, getNamespace("tools"))
    on.exit(
        assign_in_namespace("httpd", old_httpd, getNamespace("tools")),
        add = TRUE
        )

    old_wd = getwd()
    setwd(dir)
    on.exit(setwd(old_wd), add = TRUE)

    stop_server()
    on.exit(stop_server, add = TRUE)

    port = suppressMessages(tools:::startDynamicHelp(NA))
    url = paste0("http://127.0.0.1:", port)
    message("Serving directory: ", dir)
    message(paste("Served at:", url))

    browser = getOption("browser")
    browseURL(url, browser = browser)

    Sys.sleep(Inf)
    }


# render the markdown document into an incomplete HTML page
render_md = function(file){
    path = rmarkdown::render(
        input = file,
        output_format = html_fragment(),
        runtime = "static",
        knit_meta = FALSE,
        quiet = TRUE
        )
    rendered = readLines(path)
    rendered = paste0(rendered, collapse="\n")
    file.remove(path)
    rendered
    }


# get functions #
get_template = function(template){
    path = file.path("layouts", template)
    template = readLines(path)
    template
    }


# rendering functions #
render_template = function(template, data){
    page = whisker::whisker.render(template, data)
    page
    }


# sidebar will be more complex
get_sidebar = function(data){
    template = get_template("sidebar.html")
    metadata = get_metadata(data)
    types = metadata$type |> unique() |> sort() |> capitalize()
    data[["content"]] = tags(
        "a",
        content = types,
        class = "sidebar-nav-item",
        href = paste0(data["site_baseurl"], "/#", types)
        ) |> paste0(collapse = "\n")
    template = render_template(template, data)
    template
    }


# head will stay the same
get_head = function(data){
    template = get_template("head.html")
    template = render_template(template, data)
    template
    }


# render the page consisted of body, header and sidebar #
# header and sidebar are common to all pages
# and should be already contained in data
# missing reading metadata
render_md_page = function(file, template, data){
    metadata = yaml_front_matter(file)
    content = render_md(file)
    data[["page_title"]] = metadata[["title"]]
    data[["content"]] = content
    data[["page_name"]] = tools::file_path_sans_ext(file)
    render_page(template, data)
    }


# renders HTML page
render_page = function(template, data){
    page = render_template(template, data)
    writeLines(page, data$page_path)
    }


# get metadata of recipes
get_metadata = function(data){
    # collect all recipes, their names, types and date of creation
    pages_inputdir = data[["pages_inputdir"]]
    pages_outputdir = data[["pages_outputdir"]]
    site_baseurl = data[["site_baseurl"]]

    pages = dir(pages_inputdir, pattern="*.md")
    pages_path = file.path(pages_inputdir, pages)
    pages_name = tools::file_path_sans_ext(pages)
    metadata = lapply(pages_path, yaml_front_matter)
    metadata = transpose(metadata)
    metadata = as.data.frame(metadata, stringsAsFactors=FALSE)
    metadata["path"] = pages_path
    metadata["name"] = pages_name
    metadata["date"] = fix_missing_date(metadata["date"], pages_path)
    metadata["link"] = file.path(
        site_baseurl,
        pages_outputdir,
        paste0(pages_name, ".html")
        )
    metadata
    }

# tranpose list of lists according to found elements, but preserve unknown data:
transpose = function(list){
    columns = unlist(list) |> names() |> unique()
    transposed = lapply(columns, get_column, list)
    names(transposed) = columns
    transposed
    }


get_column = function(column, list){
    vec = lapply(list, getElement, name=column)
    vec[unlist(lapply(vec, is.null))] = NA
    unlist(vec)
    }


fix_missing_date = function(dates, pages_path){
    dates = dates[[1]]
    missing = is.na(dates)
    dates = as.Date(dates)
    dates[missing] = as.Date(file.mtime(pages_path[missing]))
    list(dates)
    }


# make links from metadata
make_links = function(metadata){
    links = tags(
        "a",
        content = metadata[["title"]],
        href = metadata[["link"]]
        )
    interleave(links, tag("br")) |> head(-1)
    }


capitalize = function(string){
    substr(string, 1, 1) = toupper(substr(string, 1, 1))
    string
    }


home_page = function(data){
    metadata = get_metadata(data)

    # create links for latest:
    latest_links = list()
    latest_pages = data[["latest_pages"]] |> as.numeric()
    if(latest_pages > 0){
        latest_metadata = metadata[
            metadata[["date"]] |> order(decreasing=TRUE),
            ]
        latest_pages = min(latest_pages, nrow(latest_metadata))
        latest_metadata = latest_metadata[1:latest_pages, ]
        latest_links = tag(
            "div",
            id = "Latest",
            content = c(
                tag("h3", "Latest"),
                make_links(latest_metadata)
                )
            )
        }

    # create links for each type:
    types = metadata[["type"]] |> unique() |> sort()
    type_links = list()

    for(type in types){
        type_metadata = metadata[metadata[["type"]] == type,]
        type_links[[type]] = tag(
            "div",
            id = capitalize(type),
            content = c(
                tag("h3", capitalize(type)),
                make_links(type_metadata)
                )
            )
        }
    links = paste(c(latest_links, unlist(type_links)), collapse = "\n")
    links
    }


render_home_page = function(template, data){
    data[["content"]] = home_page(data)
    data[["page_title"]] = "Recipes"
    data[["page_path"]] = "index.html"
    render_page(template, data)
    }


render_pages = function(template, data){
    pages_outputdir = data[["pages_outputdir"]]
    pages_inputdir = data[["pages_inputdir"]]

    pages = dir(pages_inputdir, pattern="*.md")
    for(page in pages){
        page_name = paste0(
            tools::file_path_sans_ext(page),
            ".html"
            )
        data[["page_path"]] = file.path(
            pages_outputdir,
            page_name
            )
        render_md_page(
            file.path(pages_inputdir, page),
            template,
            data
            )
        }
    }


create_dir = function(dir){
    if(!dir.exists(dir)){
        dir.create(dir)
        }
    }


make_site = function(data){
    create_dir(data[["pages_outputdir"]])

    head = get_head(data)
    sidebar = get_sidebar(data)
    page_template = get_template("page.html")
    recipe_template = get_template("recipe.html")

    data[["head"]] = head
    data[["sidebar"]] = sidebar

    render_home_page(page_template, data)
    render_pages(recipe_template, data)
    }


view = function(){
    baseurl = yaml::read_yaml("config.yml")[["site_baseurl"]]
    baseurl = path = sub(pattern = "^/", replace = "", baseurl)
    serve(baseurl = baseurl)
    }


build = function(){
    data = yaml::read_yaml("config.yml")
    make_site(data)
    }


clean = function(){
    data = xfun::taml_file("config.yml")
    pages_outputdir = data[["pages_outputdir"]]
    unlink(pages_outputdir, recursive=TRUE)
    invisible(file.remove("index.html"))
    }


#' Get a name of a script
#'
#' Get the name of the script's filename when run through Rscript
#'
#' For instance, for a script `script.r` in the `folder` folder,
#' it could be run as `Rscript folder/script.r`. In that case,
#' the `get_scriptname` returns the `script.r`.
get_scriptname = function(){
    args = commandArgs(FALSE)

    file_arg = grep("--file=", args, fixed=TRUE, value=TRUE)[1]

    # not run throught script
    if(length(file_arg) == 0)
        return(NULL)

    sub("^--file=", "", file_arg)
    }


usage = function(){
    prog = get_scriptname()
    blnk = strrep(" ", nchar(prog))
    cat(paste0(
"Usage: ", prog, " command ID\n",
"A simple static site generator for the CookingRecipes project\n\n",
"Commands:\n",
"Both short and long options are allowed.\n",
"  v  view   start a local html server and serve the current directory\n",
"  b  build  build site\n",
"  c  clean  clean generated files\n\n"
        ))
    }


if(sys.nframe() == 0){
    args = commandArgs(TRUE)
    if(length(args) < 1){
        usage()
        stop("Not enough arguments", call. = FALSE)
        }

    switch(args[1],
        "v" =, "view" = view(),
        "b" =, "build" = build(),
        "c" =, "clean" = clean(),
        {usage(); stop("Unknown argument \"", args[1], "\"", call. = FALSE)}
        )
    }
