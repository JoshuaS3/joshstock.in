import htmlgenerator as hg


def run(data=None):
    contents = [
        hg.LINK(rel="stylesheet", href="/static/style/core.css"),
    ]

    return contents
