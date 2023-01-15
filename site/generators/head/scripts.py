import htmlgenerator as hg


def run(data=None):
    contents = [
        # Theme switching script
        hg.SCRIPT(type="text/javascript", src="/static/js/theme.js"),
        # Banner scroll script
        hg.SCRIPT(
            type="text/javascript",
            src="/static/js/banner_scroll.js",
            defer=True,
        ),
        # Hyperlink anchors
        hg.SCRIPT(
            type="text/javascript",
            src="/static/js/anchors.js",
        ),
        # Tracking script
        hg.SCRIPT(
            hg.mark_safe(
                """var _paq = window._paq = window._paq || [];
_paq.push(["setDocumentTitle", document.domain + "/" + document.title]);
_paq.push(["setCookieDomain", "*.*.joshstock.in"]);
_paq.push(["setDomains", ["*.*.joshstock.in"]]);
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function() {
    var u="//analytics.joshstock.in/";
    _paq.push(['setTrackerUrl', u+'matomo.php']);
    _paq.push(['setSiteId', '1']);
    var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
    g.async=true; g.src=u+'matomo.js'; s.parentNode.insertBefore(g,s);
})();""",
            ),
        ),
        hg.NOSCRIPT(
            hg.P(
                hg.IMG(
                    src="//analytics.joshstock.in/matomo.php?idsite=1&rec=1",
                    border="0",
                    alt="",
                ),
            ),
        ),
    ]

    return contents
