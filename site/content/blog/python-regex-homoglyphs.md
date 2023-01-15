---
type: none
identifier: python-regex-homoglyphs
title: Patching Python's regex AST for confusable homoglyphs
description: Exploiting the re module's parsing and compiling methods to create a better automoderator.
datestring: 2022-11-06
banner_image: /static/images/futaba-filter.jpg
links:
    futaba: https://github.com/strinking/futaba
    confusable_homoglyphs: https://pypi.org/project/confusable_homoglyphs/
    Python re module: https://docs.python.org/3/library/re.html
    Scunthorpe problem: https://www.wikiwand.com/en/Scunthorpe_problem
    Abstract Syntax Trees: https://www.wikiwand.com/en/Abstract_syntax_tree
---

A couple years ago I contributed to an open source Discord
[bot](https://github.com/strinking/futaba) designed by a public computer
programming community I’m part of. As with most popular Discord bots, it
incorporates its own filter to prohibit unwanted language.  However, to ensure
coverage of messages like `as𝕕f` (notice non-ASCII `𝕕`) in case it’s told to
filter `asdf` (an ASCII-only string), the bot makes use of the
[confusable_homoglyphs](https://pypi.org/project/confusable_homoglyphs/) Python
package to automatically expand an inputted filter string to support these
non-ASCII edge cases.

Originally, the bot used base Python string manipulation to convert the
inputted filter string into a Python [regular
expression](https://docs.python.org/3/library/re.html) string that matches for
each original character as well as each character's confusable homoglyphs
(similar-looking non-ASCII characters). For example, the inputted filter string
`asdf` was converted by the bot into the following regular expression:

```bash
[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а][sｓ𝐬𝑠𝒔𝓈𝓼𝔰𝕤𝖘𝗌𝘀𝘴𝙨𝚜ꜱƽѕꮪ𑣁𐑈][dⅾⅆ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍ԁᏧᑯꓒ][f𝐟𝑓𝒇𝒻𝓯𝔣𝕗𝖋𝖿𝗳𝘧𝙛𝚏ꬵꞙſẝք]
```

This regular expression uses character sets to match one instance each of the
original character or its confusable homoglyphs. In other words, it has the
ability to catch any recognizable rendition of a word using uncommon non-ASCII
characters. This was really nice, because it meant the bot could catch most
edge cases automatically. Unfortunately, however...

## The problem

Using the method of regex generation described above precludes the use of
arbitrary regex patterns, which would help in looking at context to prevent
[false positives](https://www.wikiwand.com/en/Scunthorpe_problem). When
expanding filter strings, the bot could not differentiate between literal
characters and special regex tokens. So, instead of the valid regular
expression string `^asdf(.*)$` converting into this, preserving special regex
tokens as desired:

```bash
^[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а][sｓ𝐬𝑠𝒔𝓈𝓼𝔰𝕤𝖘𝗌𝘀𝘴𝙨𝚜ꜱƽѕꮪ𑣁𐑈][dⅾⅆ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍ԁᏧᑯꓒ][f𝐟𝑓𝒇𝒻𝓯𝔣𝕗𝖋𝖿𝗳𝘧𝙛𝚏ꬵꞙſẝք](.*)$
```

It would convert into this, mangling the original intended regex string, making
it useless for arbitrary matching:

```bash
[\^˄ˆ][a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а][sｓ𝐬𝑠𝒔𝓈𝓼𝔰𝕤𝖘𝗌𝘀𝘴𝙨𝚜ꜱƽѕꮪ𑣁𐑈][dⅾⅆ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍ԁᏧᑯꓒ][f𝐟𝑓𝒇𝒻𝓯𝔣𝕗𝖋𝖿𝗳𝘧𝙛𝚏ꬵꞙſẝք][\(［❨❲〔﴾][\.𝅭․‎܁‎‎܂‎꘎‎𐩐‎‎٠‎۰ꓸ][\*⁎‎٭‎∗𐌟][\)］❩❳〕﴿]$
```
<figcaption>Interestingly, confusable_homoglyphs doesn't list any special
characters that look similar to $.</figcaption>

## The solution

To support expansion for confusables while preserving arbitrary regex, an
**[abstract syntax tree](https://www.wikiwand.com/en/Abstract_syntax_tree)
(AST)** for the regular expression would need to be generated from the filter
string, then modified to replace predefined character literals (e.g. `a`) with
sets of their confusable homoglyphs (e.g. `[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а]`) before
being compiled into a usable pattern object. While this process appears similar
to the string manipulation method described previously, parsing first for an
AST provides a mutable structure that allows us to distinguish character
literals from special regex lexemes/grammar. Fortunately, Python’s `re` module
already contains (and exposes!!) the internal tools for parsing and
compiling—we just need to modify the process.

*The AST is generated from the inputted filter string, and the usable pattern
matching object is compiled from the AST. Since these steps are separate in
Python's `re` pipeline and since the AST is a mutable object, the AST object
can be separately modified before being compiled.*

# Manipulating Python’s regex AST

This required a bit of reverse engineering on my part as I couldn't find any
adequate documentation on the internals of Python’s `re` module. After some
brief digging in the CPython source repository, I found **two submodules of
`re` that handle regex string parsing and compilation: `re.sre_parse` and
`re.sre_compile`**, respectively.

## Reverse engineering

The `re.compile()` function uses the `sre_parse` and `sre_compile` submodules
by (effectively) doing the following to return a `re.Pattern` object:

```python
ast = re.sre_parse.parse( input_regex_string ) # -> re.sre_parse.SubPattern
pattern_object = re.sre_compile.compile( ast ) # -> re.Pattern
return pattern_object
```

Knowing this, we can experiment with the output of `sre_parse.parse()` function
to determine `re`'s AST structure and figure out how we need to modify it.

```python
>>> import re

>>> re.sre_parse.parse("asdf")
[(LITERAL, 97), (LITERAL, 115), (LITERAL, 100), (LITERAL, 102)]

>>> type(re.sre_parse.parse("asdf"))
sre_parse.SubPattern

>>> re.sre_parse.parse("[asdf]")
[(IN, [(LITERAL, 97), (LITERAL, 115), (LITERAL, 100), (LITERAL, 102)])]

>>> re.sre_parse.parse("(asdf)") # To see how `re` handles nested lexemes
[(SUBPATTERN, (1, 0, 0, [(LITERAL, 97), (LITERAL, 115), (LITERAL, 100), (LITERAL, 102)]))]
```

From this, we know the `sre_parse.parse()` function returns a `SubPattern`
list-like object containing *tuples of lexemes in the format `(LEXEME_NAME,
value)`.*

## Modifying the AST (implementing the solution)

For our case, we’re looking to replace lexemes identified as `LITERAL`s:

> `(LITERAL, ord)`, representing literal characters like `a`

with character match sets—`IN` lexemes—wrapping more `LITERAL` lexemes:

> `(IN, [ (LITERAL, ord) ... ])`, representing sets like `[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а]`

Because abstract syntax trees are, well, trees, this needs to be done
recursively to account for nested lexemes, such as those within matching
groups.

This is the solution I came up with:

```python
from collections.abc import Iterable
import re

from confusable_homoglyphs import confusables

def patched_regex(regex_string: str) -> re.Pattern:
    """
    Generate a regex pattern object after replacing literals with sets of
    confusable homoglyphs
    """

    # Generate AST from base input string
    ast_root = re.sre_parse.parse(regex_string)

    # Iterative function to patch AST
    def modify(ast_local: Iterable):

        # Step through this level of the AST
        for index, item in enumerate(ast_local):

            # Lexeme represented by item = (LEXEME_TYPE, VALUE)
            if isinstance(item, tuple):

                if item[0] == re.sre_parse.LITERAL:
                    # LITERAL type found item = (sre_parse.LITERAL, ord)

                    # Generate list of confusable homoglyphs...
                    groups = confusables.is_confusable(chr(item[1]),
                                                       greedy=True)
                    if not groups:
                        # Homoglyph is not confusable, doesn't need to be
                        # patched, move to next item in subpattern
                        continue

                    confusable_literals = [item] # Begin the homoglyph set with
                                                 # the original character lexeme
                    for homoglyph in groups[0]["homoglyphs"]:
                        confusable_literals += [ # Append confusable homoglyph
                                                 # lexemes to set
                            (re.sre_parse.LITERAL, ord(char))
                            for char in homoglyph["c"]
                        ]

                    # Overwrite the original LITERAL lexeme in the AST with the
                    # new set of confusable homoglyphs
                    ast_local[index] = (re.sre_parse.IN, confusable_literals)
                else:
                    # Not LITERAL; more possible lexemes nested in this one
                    # Convert to list, recurse, output back to tuple, then
                    # overwrite in AST
                    ast_local[index] = tuple(modify(list(item)))

            elif isinstance(item, re.sre_parse.SubPattern):
                # More possible lexemes, recurse and overwrite in AST
                ast_local[index] = modify(item)

        return ast_local

    # Patch generated base AST
    ast_root = modify(ast_root)

    # Compile AST to case-insensitive re.Pattern and return
    return re.sre_compile.compile(ast_root, re.IGNORECASE)
```

Testing the generated regular expression pattern with the example input string
from earlier, we can see it now works as expected.

```python
>>> pattern = patched_regex("^asdf(.*)$")

>>> pattern.match("Not a match")
None

>>> pattern.match("Not a match even though asdf is in it because it doesn't follow the regex pattern")
None

>>> pattern.match("asdf")
<re.Match object; span=(0, 4), match='asdf'>

>>> pattern.match("asdf match")
<re.Match object; span=(0, 10), match='asdf match'>

>>> pattern.match("𝜶ꮪ𝚍𝖿") # String containing confusable homoglyphs
<re.Match object; span=(0, 4), match='𝜶ꮪ𝚍𝖿'>

>>> pattern2 = patch_regex("^asdf\\$(.*)$") # Also works when escaping special characters

>>> pattern2.match("asdf match?")
None

>>> pattern2.match("asdf$ match?")
<re.Match object; span=(0, 11), match='asdf$ match'>
```
<figcaption>This works likewise with re.Pattern.search() and other re.Pattern
functions.</figcaption>

I submitted a [pull request](https://github.com/strinking/futaba/pull/368) to
the bot which would make any filter string prefixed by `regex:` use a custom
regex compilation process similar to the one above. This allows the Discord bot
to employ arbitrary regular expressions as filter items, making use of
supported regex features such as lookarounds, while still preserving expansion
for non-ASCII confusable homoglyphs.
