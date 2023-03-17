---
type: article
identifier: python-regex-homoglyphs
title: Patching Python's regex AST for confusable homoglyphs
description: Exploiting the re module's parsing and compiling methods to check for "confusable homoglyphs" and create a better automoderator.
datestring: 2023-03-17
banner_image: /static/images/futaba-filter.jpg
links:
    futaba: https://github.com/strinking/futaba
    confusable_homoglyphs: https://pypi.org/project/confusable_homoglyphs/
    Python re module: https://docs.python.org/3/library/re.html
    Scunthorpe problem: https://www.wikiwand.com/en/Scunthorpe_problem
    Abstract Syntax Tree (AST): https://www.wikiwand.com/en/Abstract_syntax_tree
---

A couple years ago I contributed to an open source Discord
[bot](https://github.com/strinking/futaba) designed by a public computer
programming community I’m part of. As with most popular Discord bots, it
incorporates its own filter to prohibit unwanted language.  However, to ensure
coverage of messages like `as𝕕f` (notice non-ASCII `𝕕`) in case it’s told to
filter `asdf` (an ASCII-only string), the bot makes use of the
[confusable_homoglyphs](https://pypi.org/project/confusable_homoglyphs/) Python
package to automatically expand an inputted filter string to cover these
non-ASCII edge cases.

Originally, the bot used Python's native string manipulation to convert the
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
expression string `^asdf(.*)$` (which matches "asdf" followed by anything else,
only if "asdf" is at the beginning) being converted into the following,
preserving special regex tokens as desired...

```bash
^[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а][sｓ𝐬𝑠𝒔𝓈𝓼𝔰𝕤𝖘𝗌𝘀𝘴𝙨𝚜ꜱƽѕꮪ𑣁𐑈][dⅾⅆ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍ԁᏧᑯꓒ][f𝐟𝑓𝒇𝒻𝓯𝔣𝕗𝖋𝖿𝗳𝘧𝙛𝚏ꬵꞙſẝք](.*)$
```

...it would convert into this, mangling the original intended regex string,
making it useless for arbitrary matching:

```bash
[\^˄ˆ][a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а][sｓ𝐬𝑠𝒔𝓈𝓼𝔰𝕤𝖘𝗌𝘀𝘴𝙨𝚜ꜱƽѕꮪ𑣁𐑈][dⅾⅆ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍ԁᏧᑯꓒ][f𝐟𝑓𝒇𝒻𝓯𝔣𝕗𝖋𝖿𝗳𝘧𝙛𝚏ꬵꞙſẝք][\(［❨❲〔﴾][\.𝅭․‎܁‎‎܂‎꘎‎𐩐‎‎٠‎۰ꓸ][\*⁎‎٭‎∗𐌟][\)］❩❳〕﴿]$
```
<figcaption>Interestingly, the confusable_homoglyphs package doesn't list any
special characters that look similar to <code>$</code>.</figcaption>

## The solution

To support expansion for confusables while preserving arbitrary regex, we need
to generate an **[abstract syntax
tree](https://www.wikiwand.com/en/Abstract_syntax_tree) (AST)** for the regular
expression and manipulate that somehow. For structured languages, an AST
represents the layout of significant tokens based on a predefined grammar or
syntax.  For example, regex parsers have to correctly interpret `[` and `]` as
special characters defining a set of characters within—unless they're escaped,
like `\[` and `\]`, in which case they'll be taken as "literal" bracket
characters.

After generating an AST for the regular expression, we then must modify it to
replace predefined character literals (e.g. `a`) with sets of their confusable
homoglyphs (e.g. `[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а]`) before compiling the AST into a
usable pattern-matching object. While this process appears similar to the
string manipulation method described previously, parsing first for an AST
provides a mutable structure that allows us to distinguish character literals
from special regex tokens/grammar. Fortunately, Python’s `re` module already
contains (and exposes!) the internal tools for parsing and compiling—we just
need to modify the process.

**<i>The AST is generated from the inputted filter string, and the usable
pattern matching object is compiled from the AST. Since these steps are
separate in Python's `re` pipeline and since the AST is a mutable object, the
AST object can be separately modified before being compiled.</i>**

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

>>> re.sre_parse.parse("(asdf)") # To see how `re` handles nested tokens
[(SUBPATTERN, (1, 0, 0, [(LITERAL, 97), (LITERAL, 115), (LITERAL, 100), (LITERAL, 102)]))]
```

From this, we know the `sre_parse.parse()` function returns a `SubPattern`
list-like object containing *tuples of tokens in the format `(TOKEN_NAME,
TOKEN_VALUE)`.* Also, given the name `SubPattern`, it's likely this is nested
for other types of regex grammar (maybe for lookarounds or matching groups?).

## Modifying the AST (implementing the solution)

For our case, we’re looking to replace tokens identified as `LITERAL`s:

> `(LITERAL, ord)`, representing literal characters like `a`

with character match sets—`IN` tokens—wrapping more `LITERAL` tokens:

> `(IN, [ (LITERAL, ord) ... ])`, representing sets like `[a⍺ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊ɑα𝛂𝛼𝜶𝝰𝞪а]`

Because abstract syntax trees are, well, trees, this needs to be done
recursively to account for nested tokens, such as those within matching groups.
What's important to note here is that regex does not allow nested character
sets. So, if the input string uses sets natively, and we want to expand the
characters in that set to cover confusable homoglyphs, we need to make sure we
aren't creating a new set within the original set. You can see how I
accomplished this below.

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

    # Generate list of confusable homoglyphs LITERALs based on input
    # character, including input character
    def generate_confusables(confusable: chr) -> list:
        groups = confusables.is_confusable(confusable, greedy=True)

        # Begin the homoglyph set with the original character
        confusable_literals = [(re.sre_parse.LITERAL, ord(confusable))]

        if not groups:
            # Nothing to be confused with the original character
            return confusable_literals

        # Append confusable homoglyph tokens to list
        for homoglyph in groups[0]["homoglyphs"]:
            confusable_literals += [
                (re.sre_parse.LITERAL, ord(char))
                for char in homoglyph["c"]
            ]
        return confusable_literals

    # Iterative function to patch AST
    def modify(ast_local: Iterable):

        # Step through this level of the AST
        for index, item in enumerate(ast_local):

            # Token represented by tuple (TOKEN_NAME, TOKEN_VALUE)
            if isinstance(item, tuple):

                token_name, token_value, *_ = item

                if token_name == re.sre_parse.IN:
                    # IN type found, (IN, [ (LITERAL, ord) ... ])
                    # Because you can't nest sets in regex, these need to be
                    # handled separately, with confusables inserted in place

                    confusables = []
                    for literal in token_value:
                        confusables += generate_confusables(chr(literal[1]))
                    literal_list += confusables

                elif token_name == re.sre_parse.LITERAL:
                    # LITERAL type found, (LITERAL, ord)
                    # *NOT* in a set, replace with set

                    # Generate list of confusable homoglyphs based on `ord`
                    confusables = generate_confusables(chr(token_value))

                    # Overwrite the original LITERAL token in the AST with a
                    # set of confusable homoglyphs
                    ast_local[index] = (re.sre_parse.IN, confusables)

                else:
                    # Not LITERAL or IN; more possible tokens nested in this
                    # one. Convert to list, recurse, output back to tuple, then
                    # overwrite in AST
                    ast_local[index] = tuple(modify(list(item)))

            elif isinstance(item, re.sre_parse.SubPattern):
                # More possible tokens, recurse and overwrite in AST
                ast_local[index] = modify(item)

        return ast_local

    # Patch generated native AST
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

I submitted a pull request to the bot which would make any filter string
prefixed by `regex:` use a custom regex compilation process similar to the one
above. This allows the Discord bot to employ arbitrary regular expressions as
filter items, making use of supported regex features such as lookarounds, while
still preserving expansion for non-ASCII confusable homoglyphs.
