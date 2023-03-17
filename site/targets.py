# targets.py / Template engine for my website
# Joshua Stockin / josh@joshstock.in / https://joshstock.in

# Python standard lib
import os
import html
from datetime import datetime, timezone, timedelta
from xml.dom import minidom

# External libraries
import markdown2
import htmlgenerator as hg
import readtime
import sass
from feedgen.feed import FeedGenerator

# Local imports
from _utils import dotdict as namespace, current_dir, load_generators, list_files

# Site generation metadata
CONTENT_DIRECTORY = os.path.join(current_dir(), "content")
SASS_DIRECTORY    = os.path.join(current_dir(), "style")
STATIC_DIRECTORY  = os.path.join(current_dir(), "static")

blog_description = "Barely coherent ramblings about engineering projects, software, hardware, and other things."

# Fetch generator functions
GENERATORS_MODULE = "generators"
GENERATORS = [
    "head.head",
    "topbar",
    "footer",
    "blog.article",
    "blog.index",
    "blog.listing",
]
generate = load_generators(GENERATORS_MODULE, GENERATORS)

def render_basic_page(page_data, *contents):
    # construct page
    page_generator = hg.HTML(
        generate("head.head", page_data),
        hg.BODY(
            *generate("topbar", page_data),
            hg.DIV(
                hg.DIV(
                    hg.mark_safe(contents[0]), _class="content-body"
                ),
                hg.DIV(_class="vfill"),
                generate("footer"),
                _class="content-container",
            ),
            onscroll="scroll()",
        ),
    )
    return hg.render(page_generator, {}).encode("utf-8")


# Site template implementation; returns dict {filename: data}
def template() -> {str: str}:
    files = {}

    # sitemap.xml
    sitemap_root = minidom.Document()
    sitemap_urlset = sitemap_root.createElementNS("http://www.sitemap.org/schemas/sitemap/0.9", "urlset")
    sitemap_urlset.setAttribute("xmlns", sitemap_urlset.namespaceURI)
    sitemap_root.appendChild(sitemap_urlset)
    def add_sitemap_url(url, priority=1.0):
        # <url>
        url_obj = sitemap_root.createElement("url")
        #   <loc>
        loc_obj = sitemap_root.createElement("loc")
        loc_obj.appendChild(sitemap_root.createTextNode(url))
        url_obj.appendChild(loc_obj)
        #   </loc>
        #   <priority>
        priority_obj = sitemap_root.createElement("priority")
        priority_obj.appendChild(sitemap_root.createTextNode(str(priority)))
        url_obj.appendChild(priority_obj)
        #   </priority>
        sitemap_urlset.appendChild(url_obj)
        # </url>

    # Atom and RSS feeds for blog
    articles_list = []
    fg = FeedGenerator()
    fg.id("https://joshstock.in/blog")
    fg.title("Blog - Josh Stockin")
    fg.author({"name": "Josh Stockin", "email": "josh@joshstock.in", "uri": "https://joshstock.in"})
    fg.link(href="https://joshstock.in/blog", rel="alternate")
    fg.subtitle(blog_description)
    fg.language("en")

    # Setup for string templating
    website_pages = []
    class template_string_dict(dict):
        def __missing__(self, key):
            return "{" + key  + "}"
    template_strings = template_string_dict()

    # Iterate over content directory for markdown files
    for content_file in list_files(CONTENT_DIRECTORY, ".md"):
        f = open(content_file, "r")
        data = f.read()
        f.close()

        # Compile markdown as markdown2 object with HTML, metadata
        content_html = markdown2.markdown(
            data,
            safe_mode=False,
            extras=[
                "code-friendly",
                "cuddled-lists",
                "fenced-code-blocks",
                "footnotes",
                "header-ids",
                "metadata",
                "strike",
                "tables",
                "wiki-tables",
                "tag-friendly",
                "target-blank-links",
            ],
        )

        # Normalize content metadata
        page_data = namespace(content_html.metadata)
        page_data.link = page_data.link or ""
        page_data.banner_image = page_data.banner_image or ""
        page_data.thumbnail = page_data.thumbnail or page_data.banner_image

        # type=="website"
        if page_data.type == "website":
            # save for templating later
            website_pages.append((content_html, page_data))
        # type=="website"

        # type=="article"
        elif page_data.type == "article":
            # Blog article page metadata
            page_data.readtime = readtime.of_html(content_html, wpm=150)
            page_data.link = "/blog/" + page_data.identifier
            page_data.links = page_data.links or {}
            page_data.content = content_html
            articles_list += [page_data]

            rendered = render_basic_page(page_data, hg.render(hg.DIV(*generate("blog.article", page_data)), {}))

            # render, export, add to sitemap
            files["blog/" + page_data.identifier + ".html"] = rendered
            add_sitemap_url("/blog/" + page_data.identifier, priority=0.6)
        # type=="article"

        # type=="project"
        elif page_data.type == "project":
            pass
            add_sitemap_url("/projects/" + page_data.identifier, priority=0.6)
        # type=="project"

    # end of content md files

    # Template strings
    articles_list = sorted(articles_list, key=lambda x: x.datestring, reverse=True)
    template_strings["articles_list"] = hg.render(hg.DIV(*[generate("blog.listing", x) for x in articles_list]), {})
    #template_strings["projects_list"] = ""

    # Apply templates
    for website_page in website_pages:
        content_html = website_page[0]
        page_data = website_page[1]

        templated = content_html.format_map(template_strings)
        rendered = render_basic_page(page_data, templated)

        files[page_data.index] = rendered
        if page_data.index != "index.html":
            add_sitemap_url("/" + page_data.index.rsplit(".html")[0], priority=0.8)
        else:
            add_sitemap_url("/", priority=1.0)

    # Create article entries for feed generator
    for page_data in articles_list:
        fe = fg.add_entry()
        fe.id("https://joshstock.in/blog/" + page_data.identifier)
        fe.author({"name": "Josh Stockin", "email": "josh@joshstock.in", "uri": "https://joshstock.in"})
        fe.title(page_data.title)
        fe.summary(page_data.description + " / https://joshstock.in/blog/" + page_data.identifier)
        datetime_pub = datetime.strptime(page_data.datestring, "%Y-%m-%d").replace(tzinfo=timezone(-timedelta(hours=6)))
        fe.published(datetime_pub)
        fe.updated(datetime_pub)
        fe.link(href="https://joshstock.in/blog/" + page_data.identifier)

    # Generate Atom and RSS fees for blog
    fg.link(href="https://joshstock.in/atom", rel="self")
    files["atom.xml"] = fg.atom_str(pretty=True)
    fg.link(href="https://joshstock.in/rss", rel="self", replace=True)
    files["rss.xml"] = fg.rss_str(pretty=True)

    # Compile Sass stylesheets
    for stylesheet_file in list_files(SASS_DIRECTORY, ".scss"):
        if os.path.basename(stylesheet_file)[0] != "_":
            files[
                os.path.join(
                    "static",
                    "style",
                    os.path.splitext(os.path.relpath(stylesheet_file, SASS_DIRECTORY))[
                        0
                    ]
                    + ".css",
                )
            ] = sass.compile(filename=stylesheet_file, output_style="compressed").encode("utf-8")

    # Copy content from static files
    for static_file in list_files(STATIC_DIRECTORY):
        f = open(static_file, "rb")
        data = f.read()
        f.close()

        files[
            os.path.join("static", os.path.relpath(static_file, STATIC_DIRECTORY))
        ] = data

    # Compile XML, export sitemap
    files["sitemap.xml"] = sitemap_root.toprettyxml(indent="\t").encode("utf-8")

    return files
