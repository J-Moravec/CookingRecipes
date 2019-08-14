# CookingRecipes
## with custom Static Site Generator

The `ssg.r` is a simple static site generator to produce my CookingRecipes website. This site is just set of recipes in electronic form for me and anyone else. You are free to copy recipes and the `ssg.r` script as well. But please, if you do, reference me and send me a link, because I am kind of curious person:)

The `ssg.r` do all the basic things, like translating `.md` into `.html`, reading metadata, reading `config.yml` and so on.

The live page with recipes is available [here](https://j-moravec.github.io/CookingRecipes/)

### Basic usage

To build site locally, type:

```R
Rscript ssg.r --serve # or -s
Rscript ssg.r --view # or -v
```

To build site for publication (such as on github):

```R
Rscript ssg.r --build # or -b
```

### Used packages:

* **servr** for HTML server written in R
* **whisker** mustache implementation in R
* **rmarkdown** for translating `.md` files
* **yaml** for reading YAML configuration
* **html** to make typing html tags easier

Apart of these, I also use:

* **argparser** the best commands parser in R, written purely in R
* **magrittr** for pipes

### Mustache templates:
Two basic tags should be used, the escaped tag: `{{ tag }}` and unescaped tag: `{{{ tag }}}`. Escaped tag should be used for non-HTML, so site name, description and tagline. Escaped tag is used to insert particular template (such as header) into another template (such as the site body). For more information, see [main site](http://mustache.github.io/)

### config.yml
`ssg.r` takes all `.md` pages in `pages_inputdir` and build them as `.html` in `pages_outputdir`. This setting can be changed my modifing respective values in `config.yml`. Other setting parameters include: `latest_pages` for the "Latest" section and `site_baseurl` when the site is build to be viewed on github or so.

You can also add `{{ tag }}` into the templates and its value into this config file.
