import htmlgenerator as hg


def run(data):
    header = [hg.DIV(
        _class="banner-image"
        if not data.type == "article"
        else "banner-image blog-banner",
        style=f"background-image: url({data.banner_image or '/static/images/river.jpg'})",
    ),
    hg.DIV(
        hg.UL(
            hg.LI(hg.B(hg.A("JOSH STOCKIN", href="/")), _class="title"),
            hg.DIV(
                hg.LI(hg.A("Blog", href="/blog")),
                hg.LI(hg.A("Git", href="https://git.joshstock.in")),
                hg.LI(hg.A("Projects", href="/projects")),
                hg.LI(hg.A("Resume", href="/resume")),
                _class="wrap-group",
            ),
            hg.LI(_class="hfill"),
            hg.DIV(
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/github.svg", _class="inline svg icon"),
                        href="/u/github",
                    ),
                    title="GitHub",
                ),
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/gitlab.svg", _class="inline svg icon"),
                        href="/u/gitlab",
                    ),
                    title="GitLab",
                ),
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/linkedin.svg", _class="inline svg icon"),
                        href="/u/linkedin",
                    ),
                    title="LinkedIn",
                ),
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/youtube.svg", _class="inline svg icon"),
                        href="/u/youtube",
                    ),
                    title="YouTube",
                ),
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/twitter.svg", _class="inline svg icon"),
                        href="/u/twitter",
                    ),
                    title="Twitter",
                ),
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/email.svg", _class="inline svg icon"),
                        href="mailto:josh@joshstock.in",
                    ),
                    title="Email",
                ),
                hg.LI(
                    hg.A(
                        hg.IMG(src="/static/svg/rss.svg", _class="inline svg icon"),
                        href="/atom",
                    ),
                    title="Atom Feed",
                ),
                hg.LI(
                    hg.IMG(src="", _class="inline svg icon darkmodetoggle"),
                    onclick="toggleDarkMode()",
                    title="Toggle dark mode",
                ),
                _class="wrap-group",
            ),
            _class="topbar",
        ),
        _class="topbar-container",
    )]
    return header
