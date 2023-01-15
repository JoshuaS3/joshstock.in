from . import meta
from . import styles
from . import scripts

import htmlgenerator as hg


def run(data):
    head = hg.HEAD(*meta.run(data), *styles.run(data), *scripts.run(data))
    return head
