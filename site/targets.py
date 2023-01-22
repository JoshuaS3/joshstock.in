# targets.py / Template engine for my website
# Joshua Stockin / josh@joshstock.in / https://joshstock.in

import os
import html
from datetime import datetime, timezone, timedelta
from xml.dom import minidom

import markdown2
import htmlgenerator as hg
import readtime
import sass
from feedgen.feed import FeedGenerator

from _utils import dotdict as namespace, current_dir, load_generators, list_files

# Site generation metadata
CONTENT_DIRECTORY = os.path.join(current_dir(), "content")
SASS_DIRECTORY = os.path.join(current_dir(), "style")
STATIC_DIRECTORY = os.path.join(current_dir(), "static")

blog_description = "Barely coherent ramblings about engineering projects, software, hardware, and other things."

# Fetch generator functions
GENERATORS_MODULE = "generators"
GENERATORS = [
    "head.head",
    "header",
    "footer",
    "blog.article",
    "blog.index",
    "blog.listing",
]

generate = load_generators(GENERATORS_MODULE, GENERATORS)

sitemap_root = minidom.Document()
sitemap_urlset = sitemap_root.createElementNS("http://www.sitemap.org/schemas/sitemap/0.9", "urlset")
sitemap_urlset.setAttribute("xmlns", sitemap_urlset.namespaceURI)
sitemap_root.appendChild(sitemap_urlset)

site_footer = generate("footer")

def add_sitemap_url(url):
    url_obj = sitemap_root.createElement("url")
    loc_obj = sitemap_root.createElement("loc")
    loc_obj.appendChild(sitemap_root.createTextNode(url))
    url_obj.appendChild(loc_obj)
    sitemap_urlset.appendChild(url_obj)


# Site template implementation; returns dict {filename: data}
def template() -> {str: str}:
    files = {}

    articles_list = []
    fg = FeedGenerator()
    fg.id("https://joshstock.in/blog")
    fg.title("Blog - Josh Stockin")
    fg.author({"name": "Josh Stockin", "email": "josh@joshstock.in", "uri": "https://joshstock.in"})
    fg.link(href="https://joshstock.in/blog", rel="alternate")
    fg.subtitle(blog_description)
    fg.link(href="https://joshstock.in/atom", rel="self")
    fg.language("en")

    for content_file in list_files(CONTENT_DIRECTORY, ".md"):
        f = open(content_file, "r")
        data = f.read()
        f.close()

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

        page_data = namespace(content_html.metadata)

        page_data.link = page_data.link or ""

        if page_data.type == "website":
            page_generator = hg.HTML(
                generate("head.head", page_data),
                hg.BODY(
                    *generate("header", page_data),
                    hg.DIV(
                        hg.DIV(hg.mark_safe(content_html), _class="content-body"),
                        hg.DIV(_class="vfill"),
                        site_footer,
                        _class="content-container",
                    ),
                    onscroll="scroll()",
                ),
            )
            files[page_data.index] = hg.render(page_generator, {}).encode("utf-8")
            if page_data.index != "index.html":
                add_sitemap_url("/" + page_data.index.rsplit(".html")[0])
            else:
                add_sitemap_url("/")

        elif page_data.type == "article":  # Blog article handling
            page_data.readtime = readtime.of_html(content_html, wpm=150)
            page_data.thumbnail = page_data.banner_image
            page_data.link = "/blog/" + page_data.identifier
            page_data.links = page_data.links or {}
            articles_list += [generate("blog.listing", page_data)]
            page_data.content = content_html

            fe = fg.add_entry()
            fe.id("https://joshstock.in/blog/" + page_data.identifier)
            fe.author({"name": "Josh Stockin", "email": "josh@joshstock.in", "uri": "https://joshstock.in"})
            fe.title(page_data.title)
            fe.summary(page_data.description + " / https://joshstock.in/blog/" + page_data.identifier)
            datetime_pub = datetime.strptime(page_data.datestring, "%Y-%m-%d").replace(tzinfo=timezone(-timedelta(hours=6)))
            fe.published(datetime_pub)
            fe.updated(datetime_pub)
            fe.link(href="https://joshstock.in/blog/" + page_data.identifier)

            page_generator = hg.HTML(
                generate("head.head", page_data),
                hg.BODY(
                    *generate("header", page_data),
                    hg.DIV(
                        hg.DIV(
                            *generate("blog.article", page_data), _class="content-body"
                        ),
                        hg.DIV(_class="vfill"),
                        site_footer,
                        _class="content-container",
                    ),
                    onscroll="scroll()",
                ),
            )

            files["blog/" + page_data.identifier + ".html"] = hg.render(
                page_generator, {}
            ).encode("utf-8")

    # Create blog index page
    blog_page_data = namespace(
        title="Blog",
        banner_image="",
        thumbnail="",
        link="/blog",
        description=fg.subtitle(),
    )
    blog_page_generator = hg.HTML(
        generate("head.head", blog_page_data),
        hg.BODY(
            *generate("header", blog_page_data),
            hg.DIV(
                hg.DIV(
                    hg.DIV(
                        hg.H1("Blog ", hg.IMG(src="/static/svg/memo.svg", _class="inline svg")),
                        hg.P(
                            fg.subtitle(), hg.BR(),
                            hg.SPAN("[", hg.A("Atom feed", href="/atom"), "] ", style="font-size: 0.75em; color: var(--caption-color)"),
                            hg.SPAN("[", hg.A("RSS feed", href="/rss"), "]", style="font-size: 0.75em; color: var(--caption-color)")
                        )
                    ),
                    *articles_list,
                    _class="content-body",
                ),
                hg.DIV(_class="vfill"),
                site_footer,
                _class="content-container",
            ),
            onscroll="scroll()",
        ),
    )
    files["blog.html"] = hg.render(blog_page_generator, {}).encode("utf-8")
    add_sitemap_url("/blog")

    # Feeds
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

    files["sitemap.xml"] = sitemap_root.toprettyxml(indent="\t").encode("utf-8")

    return files
