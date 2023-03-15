import htmlgenerator as hg


def run(data):
    contents = [
        hg.DIV(
            hg.P(hg.A(hg.IMG(src="/static/svg/left.svg", _class="inline svg icon"), " Back", href="/blog"), _class="back-button"),
            hg.H1(data.title, _class="title"),
            hg.P(
                data.description,
                _class="description",
            ),
            hg.P(
                hg.B(data.datestring, _class="datetime"),
                hg.I(data.readtime, _class="readtime", title="at 150wpm"),
            ),
            _class="blog-metadata",
        ),
        hg.DIV(
            hg.mark_safe(data.content),
            _class="blog-content",
        ),
        hg.DIV(
            hg.H2("Links", id="links") if len(data.links) > 0 else "",
            hg.UL(*[
                hg.LI(
                    hg.SPAN(link, style="margin-right: 0.5em"),
                    hg.I(hg.A(data.links[link] if not data.links[link].startswith("/static") else data.links[link].split("/")[-1], href=data.links[link], target="_blank")),
                )
                for link in data.links
            ]),
            hg.P(
                hg.B("Article hyperlink: "),
                hg.I(hg.A(
                    f"https://joshstock.in/blog/{data.identifier}",
                    href=f"/blog/{data.identifier}",
                )),
            ),
            hg.H2("Comments", id="comments"),
            hg.P(
                hg.I(
                    "To prevent spam, anonymous comments are held for moderation and may take a few days to appear."
                )
            ),
            hg.DIV(id="commento"),
            hg.SCRIPT(defer=True, src="https://comments.joshstock.in/js/commento.js"),
            _class="blog-end",
        ),
    ]

    return contents
