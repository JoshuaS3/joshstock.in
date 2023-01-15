from .._variables import verify
import htmlgenerator as hg


def run(data):
    """Build HTML meta tags and insert tracking script"""

    verify(data, ["title", "description", "thumbnail", "link"])

    contents = [
        hg.META(http_equiv="content-type", content="text/html; charset=utf-8"),
        hg.META(name="format-detection", content="telephone=no,date=no,address=no,email=no,url=no"),
        hg.TITLE(f"{data.title} - Josh Stockin"),
        hg.META(name="title", content=f"{data.title} - Josh Stockin"),
        hg.META(name="description", content=data.description),
        hg.META(property="og:site_name", content="Josh Stockin"),
        hg.META(property="og:title", content=f"{data.title} - Josh Stockin"),
        hg.META(property="og:description", content=data.description),
        hg.META(property="og:type", content="website"),
        hg.META(
            property="og:image",
            content=data.thumbnail
            if data.thumbnail != ""
            else "https://joshstock.in/static/images/river.jpg",
        ),
        hg.META(property="og:url", content=f"https://joshstock.in{data.link}"),
        hg.META(property="twitter:card", content="summary_large_image"),
    ]

    return contents
