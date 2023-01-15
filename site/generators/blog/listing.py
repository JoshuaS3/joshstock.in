import htmlgenerator as hg


def run(data):
    """Build HTML listing for blog article"""

    link = f"/blog/{data.identifier}"

    listing = hg.DIV(
        hg.A(
            hg.DIV(
                style=f"background-image: url({data.banner_image})",
            ),
            href=link,
            _class="blog-banner thumb",
        ),
        hg.DIV(
            hg.P(
                hg.B(data.datestring, _class="datetime"),
                hg.I(f"({data.readtime})", _class="readtime", title="at 150wpm"),
            ),
            hg.H2(hg.A(data.title, href=link), _class="title"),
            hg.P(data.description, _class="description"),
            hg.SPAN(hg.A("Read ", hg.IMG(src="/static/svg/right.svg", _class="inline svg icon"), href=link), style="font-weight:bolder"),
            _class="blog-listing-container",
        ),
        _class="blog-listing",
    )
    return listing
