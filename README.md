# CookingRecipes
## with custom Static Site Generator v2

The `ssg.r` is a simple static site generator to produce my CookingRecipes website. This site is just set of recipes in electronic form for me and anyone else. You are free to copy recipes and the `ssg.r` script as well. But please, if you do, reference me and send me a link, because I am kind of curious person:)

The `ssg.r` do all the basic things, like translating `.md` into `.html`, reading metadata, reading `config.yml` and so on.

The live page with recipes is available [here](https://j-moravec.github.io/CookingRecipes/)

### Basic usage

To build and view site, type:

```r
Rscript ssg.r build # or b
Rscript ssg.r view  # or b
```

There is no need to rebuild the site remote viewing.

### Used packages:

We use only 3 direct dependencies (4 in total)
A new rewrite made this very minimal with only 3 direct dependencies:

* **litedown** for translationg `.md` files
* **xfun** for YAML and few other utilities
* **whiskers** for templates

`whiskers` is dependency-free and `litedown` depends only on `xfun` and the `commonmark` packages.
This means in total, we have only 4 dependencies!

### minimalism

While `ssg.r` was always meant to be a simple static site generator, it was reather heavy.
With the rewrite, we went from some ~40 recursive depenedencies to only 4 non-base ones.
Less dependencies means less breakage, less hidden complexity, more control and more stability.

* **magrittr** was used for pipe `%>%`, replaced with native pipe `|>`
* **argparser** was used for parsing command line arguments, replaced with a single `switch` command
* **html** was used to define html tags, replaced with a single `tag()` function
* **servr** was used to serve static site, replaced with a hack of R's build-in http server for dynamic help from the base `tools` pkg
* **rmarkdown** for translating `.md` into `.html` and with some 40 dependencies, replaced with much lighter `litedown` with only 2 dependencies
* **yaml** for reading YAML configuration, replaced with `xfun` (`litedown`'s dependency)

Many of these changes were quite minimal and didn't required big rewrite.
In some cases, it lead to a better behaviour, such as not needing to rebuild the blog for local and remote viewing.

### serve: tools::startDynamicHelp hack

Instead of the dependency heavy `servr`, we are now using a hack of the build-in http server that is used to display dynamic help.

By replacing the `tools:::httpd`, we can run our own `httpd` function using the `tools::startDynamicHelp()`.

More information is in a [separate repository](https://github.com/J-Moravec/serve).
This function was further customized to replace baseurl, removing the need to rebuild the server for local (without baseurl) and remote (with baseurl) viewing, which is a common issue for many static site generators including Quarto.

Don't try to put this into a CRAN package or you would get some angry emails!
Touching internal functions like this with `:::` is not allowed.

### whiskers

The one dependency I kept, but could be removed, is `whiskers`.
`litedown` has its own [templates](https://yihui.org/litedown/#sec:templates) which could be used instead, but I found its system bit awkward to reason about when used with separate header and sidebar, which are templated as well.

Using `whiskers` give us better flexibility and isolate us from some litedown's automagic that is great when creating stand-alone document, but inserts css, javascripts, and removes some control.

### Mustache templates

Two basic tags should be used, the escaped tag: `{{ tag }}` and unescaped tag: `{{{ tag }}}`. Escaped tag should be used for non-HTML, so site name, description and tagline. Escaped tag is used to insert particular template (such as header) into another template (such as the site body). For more information, see [main site](http://mustache.github.io/)

### config.yml

`ssg.r` takes all `.md` pages in `pages_inputdir` and build them as `.html` in `pages_outputdir`. This setting can be changed my modifing respective values in `config.yml`. Other setting parameters include: `latest_pages` for the "Latest" section and `site_baseurl` when the site is build to be viewed on github or so.

You can also add `{{ tag }}` into the templates and its value into this config file.
