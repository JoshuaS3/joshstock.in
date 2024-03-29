import datetime

import htmlgenerator as hg


def run(data=None):
    """Build HTML footer"""
    footer = hg.FOOTER(
        hg.P(
            hg.mark_safe(
                f"joshstock.in &copy; {datetime.date.today().year} Josh Stockin"
            ),
        ),
        hg.P(
            "[",
            hg.A("GPG key", href="/josh.gpg"),
            "] / ",
            hg.A("josh@joshstock.in", href="mailto:josh@joshstock.in"),
            " / ",
            hg.A("stockin2@illinois.edu", href="mailto:stockin2@illinois.edu"),
        ),
        hg.FIGCAPTION(
            hg.I(
                f"Site last updated {datetime.datetime.now().strftime('%Y-%m-%d, %H:%M')}"
            )
        )
    )
    return footer
