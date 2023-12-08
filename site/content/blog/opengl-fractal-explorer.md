---
type: article
identifier: opengl-fractal-explorer
title: GPU-Accelerated Fractal Explorer
description: Using OpenGL's compute shaders to dispatch fractal computation to the GPU and render in realtime.
datestring: 2023-12-07
banner_image: /static/images/mandelbrot.png
links:
    Source Code: https://github.com/JoshuaS3/zydeco/tree/fractal
    The Mandelbrot Set: https://en.wikipedia.org/wiki/Mandelbrot_set
    IEEE 754: https://en.wikipedia.org/wiki/IEEE_754
    OpenGL Compute Shaders: https://www.khronos.org/opengl/wiki/Compute_Shader
    Adam7 Algorithm: https://en.wikipedia.org/wiki/Adam7_algorithm
    OpenGL Memory Model: https://www.khronos.org/opengl/wiki/Memory_Model
---

<style>
svg {
    display: block;
    margin: 0 auto;
    color: var(--text-color);
    transform: scale(0.9);
}
</style>

I've been toying around for a while with an idea for a procedural world
generation + simulation project as an experiment in C++ and graphics
programming to teach myself more about computer science and rendering
techniques. Part of this is, of course, setting up the infrastructure for input
handling, world logic, debug menus, and rendering. When writing the initial
code, I used the Mandelbrot set for testing. This led me down a rabbit hole of
improving my rendering techniques for this application, as well as trying out
different fractals, ultimately culminating in this GPU-accelerated fractal
explorer (transform, zoom, pan) with progressive refine:

<iframe style="max-width:720px;max-height:405px;display:block;margin:0 auto 1em auto" src="https://www.youtube-nocookie.com/embed/Zqfeut60Qbc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
<figcaption style="text-align:center">Video compression doesn't allow for demonstration of the progressive refine element very well; this is explained in detail later here.</figcaption>

**Outline**
1. [Fractal Sets](#fractal-sets)
  1. [The Mandelbrot Set](#the-mandelbrot-set)
  2. [The Tricorn Set](#the-tricorn-set)
  3. [The Burning Ship Fractal](#the-burning-ship-fractal)
2. [Notes on Fractal Computation](#notes-on-fractal-computation)
  1. [Divergence](#divergence)
  2. [Iteration Count](#iteration-count)
  3. [Floating-Point Precision](#floating-point-precision)
3. [Rendering on the GPU](#rendering-on-the-gpu)
  1. [Using a Fragment Shader](#using-a-fragment-shader)
  2. [Using a Compute Shader](#using-a-compute-shader)
  3. [Progressive Refine](#progressive-refine)

# Fractal Sets

## The Mandelbrot Set

The [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set) is defined
to be the set of all numbers *c* in the complex plane for which the following
sequence (what I call a "z-transform") *does not* diverge to infinity:

<svg xmlns="http://www.w3.org/2000/svg" width="158.472px" height="67.572px" viewBox="0 -1494.5 5837.2 2488.9" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" style=""><defs><path id="MJX-26-TEX-I-1D467" d="M347 338Q337 338 294 349T231 360Q211 360 197 356T174 346T162 335T155 324L153 320Q150 317 138 317Q117 317 117 325Q117 330 120 339Q133 378 163 406T229 440Q241 442 246 442Q271 442 291 425T329 392T367 375Q389 375 411 408T434 441Q435 442 449 442H462Q468 436 468 434Q468 430 463 420T449 399T432 377T418 358L411 349Q368 298 275 214T160 106L148 94L163 93Q185 93 227 82T290 71Q328 71 360 90T402 140Q406 149 409 151T424 153Q443 153 443 143Q443 138 442 134Q425 72 376 31T278 -11Q252 -11 232 6T193 40T155 57Q111 57 76 -3Q70 -11 59 -11H54H41Q35 -5 35 -2Q35 13 93 84Q132 129 225 214T340 322Q352 338 347 338Z"></path><path id="MJX-26-TEX-N-30" d="M96 585Q152 666 249 666Q297 666 345 640T423 548Q460 465 460 320Q460 165 417 83Q397 41 362 16T301 -15T250 -22Q224 -22 198 -16T137 16T82 83Q39 165 39 320Q39 494 96 585ZM321 597Q291 629 250 629Q208 629 178 597Q153 571 145 525T137 333Q137 175 145 125T181 46Q209 16 250 16Q290 16 318 46Q347 76 354 130T362 333Q362 478 354 524T321 597Z"></path><path id="MJX-26-TEX-N-3D" d="M56 347Q56 360 70 367H707Q722 359 722 347Q722 336 708 328L390 327H72Q56 332 56 347ZM56 153Q56 168 72 173H708Q722 163 722 153Q722 140 707 133H70Q56 140 56 153Z"></path><path id="MJX-26-TEX-I-1D450" d="M34 159Q34 268 120 355T306 442Q362 442 394 418T427 355Q427 326 408 306T360 285Q341 285 330 295T319 325T330 359T352 380T366 386H367Q367 388 361 392T340 400T306 404Q276 404 249 390Q228 381 206 359Q162 315 142 235T121 119Q121 73 147 50Q169 26 205 26H209Q321 26 394 111Q403 121 406 121Q410 121 419 112T429 98T420 83T391 55T346 25T282 0T202 -11Q127 -11 81 37T34 159Z"></path><path id="MJX-26-TEX-I-1D45B" d="M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z"></path><path id="MJX-26-TEX-N-32" d="M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z"></path><path id="MJX-26-TEX-N-2212" d="M84 237T84 250T98 270H679Q694 262 694 250T679 230H98Q84 237 84 250Z"></path><path id="MJX-26-TEX-N-31" d="M213 578L200 573Q186 568 160 563T102 556H83V602H102Q149 604 189 617T245 641T273 663Q275 666 285 666Q294 666 302 660V361L303 61Q310 54 315 52T339 48T401 46H427V0H416Q395 3 257 3Q121 3 100 0H88V46H114Q136 46 152 46T177 47T193 50T201 52T207 57T213 61V578Z"></path><path id="MJX-26-TEX-N-2B" d="M56 237T56 250T70 270H369V420L370 570Q380 583 389 583Q402 583 409 568V270H707Q722 262 722 250T707 230H409V-68Q401 -82 391 -82H389H387Q375 -82 369 -68V230H70Q56 237 56 250Z"></path></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mtable"><g data-mml-node="mtr" transform="translate(0,744.5)"><g data-mml-node="mtd" transform="translate(70.7,0)"><g data-mml-node="msub"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-26-TEX-I-1D467"></use></g><g data-mml-node="mn" transform="translate(498,-150) scale(0.707)"><use data-c="30" xlink:href="#MJX-26-TEX-N-30"></use></g></g></g><g data-mml-node="mtd" transform="translate(972.3,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-26-TEX-N-3D"></use></g><g data-mml-node="mi" transform="translate(1333.6,0)"><use data-c="1D450" xlink:href="#MJX-26-TEX-I-1D450"></use></g></g></g><g data-mml-node="mtr" transform="translate(0,-689.5)"><g data-mml-node="mtd"><g data-mml-node="msub"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-26-TEX-I-1D467"></use></g><g data-mml-node="mi" transform="translate(498,-150) scale(0.707)"><use data-c="1D45B" xlink:href="#MJX-26-TEX-I-1D45B"></use></g></g></g><g data-mml-node="mtd" transform="translate(972.3,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-26-TEX-N-3D"></use></g><g data-mml-node="msubsup" transform="translate(1333.6,0)"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-26-TEX-I-1D467"></use></g><g data-mml-node="mn" transform="translate(498,413) scale(0.707)"><use data-c="32" xlink:href="#MJX-26-TEX-N-32"></use></g><g data-mml-node="TeXAtom" transform="translate(498,-247) scale(0.707)" data-mjx-texclass="ORD"><g data-mml-node="mi"><use data-c="1D45B" xlink:href="#MJX-26-TEX-I-1D45B"></use></g><g data-mml-node="mo" transform="translate(600,0)"><use data-c="2212" xlink:href="#MJX-26-TEX-N-2212"></use></g><g data-mml-node="mn" transform="translate(1378,0)"><use data-c="31" xlink:href="#MJX-26-TEX-N-31"></use></g></g></g><g data-mml-node="mo" transform="translate(3431.7,0)"><use data-c="2B" xlink:href="#MJX-26-TEX-N-2B"></use></g><g data-mml-node="mi" transform="translate(4431.9,0)"><use data-c="1D450" xlink:href="#MJX-26-TEX-I-1D450"></use></g></g></g></g></g></g></svg>

Note that the z-*squared* term is squaring a complex number, given by the
following:

<svg xmlns="http://www.w3.org/2000/svg" width="267.096px" height="66.084px" viewBox="0 -1467 9838.1 2433.9" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" style=""><defs><path id="MJX-44-TEX-I-1D450" d="M34 159Q34 268 120 355T306 442Q362 442 394 418T427 355Q427 326 408 306T360 285Q341 285 330 295T319 325T330 359T352 380T366 386H367Q367 388 361 392T340 400T306 404Q276 404 249 390Q228 381 206 359Q162 315 142 235T121 119Q121 73 147 50Q169 26 205 26H209Q321 26 394 111Q403 121 406 121Q410 121 419 112T429 98T420 83T391 55T346 25T282 0T202 -11Q127 -11 81 37T34 159Z"></path><path id="MJX-44-TEX-N-3D" d="M56 347Q56 360 70 367H707Q722 359 722 347Q722 336 708 328L390 327H72Q56 332 56 347ZM56 153Q56 168 72 173H708Q722 163 722 153Q722 140 707 133H70Q56 140 56 153Z"></path><path id="MJX-44-TEX-I-1D44E" d="M33 157Q33 258 109 349T280 441Q331 441 370 392Q386 422 416 422Q429 422 439 414T449 394Q449 381 412 234T374 68Q374 43 381 35T402 26Q411 27 422 35Q443 55 463 131Q469 151 473 152Q475 153 483 153H487Q506 153 506 144Q506 138 501 117T481 63T449 13Q436 0 417 -8Q409 -10 393 -10Q359 -10 336 5T306 36L300 51Q299 52 296 50Q294 48 292 46Q233 -10 172 -10Q117 -10 75 30T33 157ZM351 328Q351 334 346 350T323 385T277 405Q242 405 210 374T160 293Q131 214 119 129Q119 126 119 118T118 106Q118 61 136 44T179 26Q217 26 254 59T298 110Q300 114 325 217T351 328Z"></path><path id="MJX-44-TEX-N-2B" d="M56 237T56 250T70 270H369V420L370 570Q380 583 389 583Q402 583 409 568V270H707Q722 262 722 250T707 230H409V-68Q401 -82 391 -82H389H387Q375 -82 369 -68V230H70Q56 237 56 250Z"></path><path id="MJX-44-TEX-I-1D44F" d="M73 647Q73 657 77 670T89 683Q90 683 161 688T234 694Q246 694 246 685T212 542Q204 508 195 472T180 418L176 399Q176 396 182 402Q231 442 283 442Q345 442 383 396T422 280Q422 169 343 79T173 -11Q123 -11 82 27T40 150V159Q40 180 48 217T97 414Q147 611 147 623T109 637Q104 637 101 637H96Q86 637 83 637T76 640T73 647ZM336 325V331Q336 405 275 405Q258 405 240 397T207 376T181 352T163 330L157 322L136 236Q114 150 114 114Q114 66 138 42Q154 26 178 26Q211 26 245 58Q270 81 285 114T318 219Q336 291 336 325Z"></path><path id="MJX-44-TEX-I-1D456" d="M184 600Q184 624 203 642T247 661Q265 661 277 649T290 619Q290 596 270 577T226 557Q211 557 198 567T184 600ZM21 287Q21 295 30 318T54 369T98 420T158 442Q197 442 223 419T250 357Q250 340 236 301T196 196T154 83Q149 61 149 51Q149 26 166 26Q175 26 185 29T208 43T235 78T260 137Q263 149 265 151T282 153Q302 153 302 143Q302 135 293 112T268 61T223 11T161 -11Q129 -11 102 10T74 74Q74 91 79 106T122 220Q160 321 166 341T173 380Q173 404 156 404H154Q124 404 99 371T61 287Q60 286 59 284T58 281T56 279T53 278T49 278T41 278H27Q21 284 21 287Z"></path><path id="MJX-44-TEX-N-32" d="M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z"></path><path id="MJX-44-TEX-N-28" d="M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z"></path><path id="MJX-44-TEX-N-2212" d="M84 237T84 250T98 270H679Q694 262 694 250T679 230H98Q84 237 84 250Z"></path><path id="MJX-44-TEX-N-29" d="M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z"></path></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mtable"><g data-mml-node="mtr" transform="translate(0,717)"><g data-mml-node="mtd" transform="translate(436.6,0)"><g data-mml-node="mi"><use data-c="1D450" xlink:href="#MJX-44-TEX-I-1D450"></use></g></g><g data-mml-node="mtd" transform="translate(869.6,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-44-TEX-N-3D"></use></g><g data-mml-node="mi" transform="translate(1333.6,0)"><use data-c="1D44E" xlink:href="#MJX-44-TEX-I-1D44E"></use></g><g data-mml-node="mo" transform="translate(2084.8,0)"><use data-c="2B" xlink:href="#MJX-44-TEX-N-2B"></use></g><g data-mml-node="mi" transform="translate(3085,0)"><use data-c="1D44F" xlink:href="#MJX-44-TEX-I-1D44F"></use></g><g data-mml-node="mi" transform="translate(3514,0)"><use data-c="1D456" xlink:href="#MJX-44-TEX-I-1D456"></use></g></g></g><g data-mml-node="mtr" transform="translate(0,-717)"><g data-mml-node="mtd"><g data-mml-node="msup"><g data-mml-node="mi"><use data-c="1D450" xlink:href="#MJX-44-TEX-I-1D450"></use></g><g data-mml-node="mn" transform="translate(466,413) scale(0.707)"><use data-c="32" xlink:href="#MJX-44-TEX-N-32"></use></g></g></g><g data-mml-node="mtd" transform="translate(869.6,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-44-TEX-N-3D"></use></g><g data-mml-node="mo" transform="translate(1333.6,0)"><use data-c="28" xlink:href="#MJX-44-TEX-N-28"></use></g><g data-mml-node="msup" transform="translate(1722.6,0)"><g data-mml-node="mi"><use data-c="1D44E" xlink:href="#MJX-44-TEX-I-1D44E"></use></g><g data-mml-node="mn" transform="translate(562,413) scale(0.707)"><use data-c="32" xlink:href="#MJX-44-TEX-N-32"></use></g></g><g data-mml-node="mo" transform="translate(2910.3,0)"><use data-c="2212" xlink:href="#MJX-44-TEX-N-2212"></use></g><g data-mml-node="msup" transform="translate(3910.6,0)"><g data-mml-node="mi"><use data-c="1D44F" xlink:href="#MJX-44-TEX-I-1D44F"></use></g><g data-mml-node="mn" transform="translate(462,413) scale(0.707)"><use data-c="32" xlink:href="#MJX-44-TEX-N-32"></use></g></g><g data-mml-node="mo" transform="translate(4776.1,0)"><use data-c="29" xlink:href="#MJX-44-TEX-N-29"></use></g><g data-mml-node="mo" transform="translate(5387.3,0)"><use data-c="2B" xlink:href="#MJX-44-TEX-N-2B"></use></g><g data-mml-node="mo" transform="translate(6387.6,0)"><use data-c="28" xlink:href="#MJX-44-TEX-N-28"></use></g><g data-mml-node="mn" transform="translate(6776.6,0)"><use data-c="32" xlink:href="#MJX-44-TEX-N-32"></use></g><g data-mml-node="mi" transform="translate(7276.6,0)"><use data-c="1D44E" xlink:href="#MJX-44-TEX-I-1D44E"></use></g><g data-mml-node="mi" transform="translate(7805.6,0)"><use data-c="1D44F" xlink:href="#MJX-44-TEX-I-1D44F"></use></g><g data-mml-node="mo" transform="translate(8234.6,0)"><use data-c="29" xlink:href="#MJX-44-TEX-N-29"></use></g><g data-mml-node="mi" transform="translate(8623.6,0)"><use data-c="1D456" xlink:href="#MJX-44-TEX-I-1D456"></use></g></g></g></g></g></g></svg>

where *a* is the real term and *b* is the imaginary term.

When rendering, we take the real axis to be *x* and the imaginary axis to be
*y*. Points (numbers) in the set are colored black, and points not in the set
are colored with a brightness corresponding to the number of iterations
required until divergence.

The above unassuming sequence and rules of complex algebra result in perhaps
the most popular fractal shape, which exhibits infinite complexity at the
boundary of the set and yields new patterns—including copies and variations of
the set itself!—wherever you zoom in, forever.

<figure class="full">
    <img width="700px" src="/static/images/mandelbrot.png">
</figure>

Needless to say, I've been pretty fascinated by it. This isn't the only
fractal set though. You can generate more interesting shapes and
patterns by simply modifying the original sequence, or just coming up with
something new. You can also add an additional parameter to play around with,
transforming fractals. I don't get very scientific with it. You can see this
used in the video to transform between fractals. Most random variants however
are relatively boring in that they 1. don't produce more than one or two
patterns, 2. produce patterns that are just the Mandelbrot set (this by itself
is an interesting pattern of emergence), or 3. devolve into noise when zooming
in most places. There are a couple exceptions of note:

## The Tricorn Set

The Tricorn set is a variant of the Mandelbrot set that uses the *conjugate* of
z, which inverts the sign of the imaginary term.

<svg xmlns="http://www.w3.org/2000/svg" width="158.472px" height="67.572px" viewBox="0 -1494.5 5837.2 2488.9" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" style=""><defs><path id="MJX-68-TEX-I-1D467" d="M347 338Q337 338 294 349T231 360Q211 360 197 356T174 346T162 335T155 324L153 320Q150 317 138 317Q117 317 117 325Q117 330 120 339Q133 378 163 406T229 440Q241 442 246 442Q271 442 291 425T329 392T367 375Q389 375 411 408T434 441Q435 442 449 442H462Q468 436 468 434Q468 430 463 420T449 399T432 377T418 358L411 349Q368 298 275 214T160 106L148 94L163 93Q185 93 227 82T290 71Q328 71 360 90T402 140Q406 149 409 151T424 153Q443 153 443 143Q443 138 442 134Q425 72 376 31T278 -11Q252 -11 232 6T193 40T155 57Q111 57 76 -3Q70 -11 59 -11H54H41Q35 -5 35 -2Q35 13 93 84Q132 129 225 214T340 322Q352 338 347 338Z"></path><path id="MJX-68-TEX-N-30" d="M96 585Q152 666 249 666Q297 666 345 640T423 548Q460 465 460 320Q460 165 417 83Q397 41 362 16T301 -15T250 -22Q224 -22 198 -16T137 16T82 83Q39 165 39 320Q39 494 96 585ZM321 597Q291 629 250 629Q208 629 178 597Q153 571 145 525T137 333Q137 175 145 125T181 46Q209 16 250 16Q290 16 318 46Q347 76 354 130T362 333Q362 478 354 524T321 597Z"></path><path id="MJX-68-TEX-N-3D" d="M56 347Q56 360 70 367H707Q722 359 722 347Q722 336 708 328L390 327H72Q56 332 56 347ZM56 153Q56 168 72 173H708Q722 163 722 153Q722 140 707 133H70Q56 140 56 153Z"></path><path id="MJX-68-TEX-I-1D450" d="M34 159Q34 268 120 355T306 442Q362 442 394 418T427 355Q427 326 408 306T360 285Q341 285 330 295T319 325T330 359T352 380T366 386H367Q367 388 361 392T340 400T306 404Q276 404 249 390Q228 381 206 359Q162 315 142 235T121 119Q121 73 147 50Q169 26 205 26H209Q321 26 394 111Q403 121 406 121Q410 121 419 112T429 98T420 83T391 55T346 25T282 0T202 -11Q127 -11 81 37T34 159Z"></path><path id="MJX-68-TEX-I-1D45B" d="M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z"></path><path id="MJX-68-TEX-N-AF" d="M69 544V590H430V544H69Z"></path><path id="MJX-68-TEX-N-32" d="M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z"></path><path id="MJX-68-TEX-N-2212" d="M84 237T84 250T98 270H679Q694 262 694 250T679 230H98Q84 237 84 250Z"></path><path id="MJX-68-TEX-N-31" d="M213 578L200 573Q186 568 160 563T102 556H83V602H102Q149 604 189 617T245 641T273 663Q275 666 285 666Q294 666 302 660V361L303 61Q310 54 315 52T339 48T401 46H427V0H416Q395 3 257 3Q121 3 100 0H88V46H114Q136 46 152 46T177 47T193 50T201 52T207 57T213 61V578Z"></path><path id="MJX-68-TEX-N-2B" d="M56 237T56 250T70 270H369V420L370 570Q380 583 389 583Q402 583 409 568V270H707Q722 262 722 250T707 230H409V-68Q401 -82 391 -82H389H387Q375 -82 369 -68V230H70Q56 237 56 250Z"></path></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mtable"><g data-mml-node="mtr" transform="translate(0,744.5)"><g data-mml-node="mtd" transform="translate(70.7,0)"><g data-mml-node="msub"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-68-TEX-I-1D467"></use></g><g data-mml-node="mn" transform="translate(498,-150) scale(0.707)"><use data-c="30" xlink:href="#MJX-68-TEX-N-30"></use></g></g></g><g data-mml-node="mtd" transform="translate(972.3,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-68-TEX-N-3D"></use></g><g data-mml-node="mi" transform="translate(1333.6,0)"><use data-c="1D450" xlink:href="#MJX-68-TEX-I-1D450"></use></g></g></g><g data-mml-node="mtr" transform="translate(0,-689.5)"><g data-mml-node="mtd"><g data-mml-node="msub"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-68-TEX-I-1D467"></use></g><g data-mml-node="mi" transform="translate(498,-150) scale(0.707)"><use data-c="1D45B" xlink:href="#MJX-68-TEX-I-1D45B"></use></g></g></g><g data-mml-node="mtd" transform="translate(972.3,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-68-TEX-N-3D"></use></g><g data-mml-node="msubsup" transform="translate(1333.6,0)"><g data-mml-node="TeXAtom" data-mjx-texclass="ORD"><g data-mml-node="mover"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-68-TEX-I-1D467"></use></g><g data-mml-node="mo" transform="translate(288.1,3) translate(-250 0)"><use data-c="AF" xlink:href="#MJX-68-TEX-N-AF"></use></g></g></g><g data-mml-node="mn" transform="translate(498,413) scale(0.707)"><use data-c="32" xlink:href="#MJX-68-TEX-N-32"></use></g><g data-mml-node="TeXAtom" transform="translate(498,-247) scale(0.707)" data-mjx-texclass="ORD"><g data-mml-node="mi"><use data-c="1D45B" xlink:href="#MJX-68-TEX-I-1D45B"></use></g><g data-mml-node="mo" transform="translate(600,0)"><use data-c="2212" xlink:href="#MJX-68-TEX-N-2212"></use></g><g data-mml-node="mn" transform="translate(1378,0)"><use data-c="31" xlink:href="#MJX-68-TEX-N-31"></use></g></g></g><g data-mml-node="mo" transform="translate(3431.7,0)"><use data-c="2B" xlink:href="#MJX-68-TEX-N-2B"></use></g><g data-mml-node="mi" transform="translate(4431.9,0)"><use data-c="1D450" xlink:href="#MJX-68-TEX-I-1D450"></use></g></g></g></g></g></g></svg>

<figure class="full">
    <img width="700px" src="/static/images/tricorn.png">
</figure>

## The Burning Ship Fractal

A more well-known variant of the Mandelbrot set is the Burning Ship fractal,
which takes the *absolute value* of z before squaring it.

<svg xmlns="http://www.w3.org/2000/svg" width="185.424px" height="66.084px" viewBox="0 -1467 6829.8 2433.9" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" style=""><defs><path id="MJX-73-TEX-I-1D467" d="M347 338Q337 338 294 349T231 360Q211 360 197 356T174 346T162 335T155 324L153 320Q150 317 138 317Q117 317 117 325Q117 330 120 339Q133 378 163 406T229 440Q241 442 246 442Q271 442 291 425T329 392T367 375Q389 375 411 408T434 441Q435 442 449 442H462Q468 436 468 434Q468 430 463 420T449 399T432 377T418 358L411 349Q368 298 275 214T160 106L148 94L163 93Q185 93 227 82T290 71Q328 71 360 90T402 140Q406 149 409 151T424 153Q443 153 443 143Q443 138 442 134Q425 72 376 31T278 -11Q252 -11 232 6T193 40T155 57Q111 57 76 -3Q70 -11 59 -11H54H41Q35 -5 35 -2Q35 13 93 84Q132 129 225 214T340 322Q352 338 347 338Z"></path><path id="MJX-73-TEX-N-30" d="M96 585Q152 666 249 666Q297 666 345 640T423 548Q460 465 460 320Q460 165 417 83Q397 41 362 16T301 -15T250 -22Q224 -22 198 -16T137 16T82 83Q39 165 39 320Q39 494 96 585ZM321 597Q291 629 250 629Q208 629 178 597Q153 571 145 525T137 333Q137 175 145 125T181 46Q209 16 250 16Q290 16 318 46Q347 76 354 130T362 333Q362 478 354 524T321 597Z"></path><path id="MJX-73-TEX-N-3D" d="M56 347Q56 360 70 367H707Q722 359 722 347Q722 336 708 328L390 327H72Q56 332 56 347ZM56 153Q56 168 72 173H708Q722 163 722 153Q722 140 707 133H70Q56 140 56 153Z"></path><path id="MJX-73-TEX-I-1D450" d="M34 159Q34 268 120 355T306 442Q362 442 394 418T427 355Q427 326 408 306T360 285Q341 285 330 295T319 325T330 359T352 380T366 386H367Q367 388 361 392T340 400T306 404Q276 404 249 390Q228 381 206 359Q162 315 142 235T121 119Q121 73 147 50Q169 26 205 26H209Q321 26 394 111Q403 121 406 121Q410 121 419 112T429 98T420 83T391 55T346 25T282 0T202 -11Q127 -11 81 37T34 159Z"></path><path id="MJX-73-TEX-I-1D45B" d="M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z"></path><path id="MJX-73-TEX-N-7C" d="M139 -249H137Q125 -249 119 -235V251L120 737Q130 750 139 750Q152 750 159 735V-235Q151 -249 141 -249H139Z"></path><path id="MJX-73-TEX-N-2212" d="M84 237T84 250T98 270H679Q694 262 694 250T679 230H98Q84 237 84 250Z"></path><path id="MJX-73-TEX-N-31" d="M213 578L200 573Q186 568 160 563T102 556H83V602H102Q149 604 189 617T245 641T273 663Q275 666 285 666Q294 666 302 660V361L303 61Q310 54 315 52T339 48T401 46H427V0H416Q395 3 257 3Q121 3 100 0H88V46H114Q136 46 152 46T177 47T193 50T201 52T207 57T213 61V578Z"></path><path id="MJX-73-TEX-N-32" d="M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z"></path><path id="MJX-73-TEX-N-2B" d="M56 237T56 250T70 270H369V420L370 570Q380 583 389 583Q402 583 409 568V270H707Q722 262 722 250T707 230H409V-68Q401 -82 391 -82H389H387Q375 -82 369 -68V230H70Q56 237 56 250Z"></path></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mtable"><g data-mml-node="mtr" transform="translate(0,717)"><g data-mml-node="mtd" transform="translate(70.7,0)"><g data-mml-node="msub"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-73-TEX-I-1D467"></use></g><g data-mml-node="mn" transform="translate(498,-150) scale(0.707)"><use data-c="30" xlink:href="#MJX-73-TEX-N-30"></use></g></g></g><g data-mml-node="mtd" transform="translate(972.3,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-73-TEX-N-3D"></use></g><g data-mml-node="mi" transform="translate(1333.6,0)"><use data-c="1D450" xlink:href="#MJX-73-TEX-I-1D450"></use></g></g></g><g data-mml-node="mtr" transform="translate(0,-717)"><g data-mml-node="mtd"><g data-mml-node="msub"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-73-TEX-I-1D467"></use></g><g data-mml-node="mi" transform="translate(498,-150) scale(0.707)"><use data-c="1D45B" xlink:href="#MJX-73-TEX-I-1D45B"></use></g></g></g><g data-mml-node="mtd" transform="translate(972.3,0)"><g data-mml-node="mi"></g><g data-mml-node="mo" transform="translate(277.8,0)"><use data-c="3D" xlink:href="#MJX-73-TEX-N-3D"></use></g><g data-mml-node="TeXAtom" data-mjx-texclass="ORD" transform="translate(1333.6,0)"><g data-mml-node="mo" transform="translate(0 -0.5)"><use data-c="7C" xlink:href="#MJX-73-TEX-N-7C"></use></g></g><g data-mml-node="msub" transform="translate(1611.6,0)"><g data-mml-node="mi"><use data-c="1D467" xlink:href="#MJX-73-TEX-I-1D467"></use></g><g data-mml-node="TeXAtom" transform="translate(498,-150) scale(0.707)" data-mjx-texclass="ORD"><g data-mml-node="mi"><use data-c="1D45B" xlink:href="#MJX-73-TEX-I-1D45B"></use></g><g data-mml-node="mo" transform="translate(600,0)"><use data-c="2212" xlink:href="#MJX-73-TEX-N-2212"></use></g><g data-mml-node="mn" transform="translate(1378,0)"><use data-c="31" xlink:href="#MJX-73-TEX-N-31"></use></g></g></g><g data-mml-node="msup" transform="translate(3487.5,0)"><g data-mml-node="TeXAtom" data-mjx-texclass="ORD"><g data-mml-node="mo" transform="translate(0 -0.5)"><use data-c="7C" xlink:href="#MJX-73-TEX-N-7C"></use></g></g><g data-mml-node="mn" transform="translate(311,413) scale(0.707)"><use data-c="32" xlink:href="#MJX-73-TEX-N-32"></use></g></g><g data-mml-node="mo" transform="translate(4424.3,0)"><use data-c="2B" xlink:href="#MJX-73-TEX-N-2B"></use></g><g data-mml-node="mi" transform="translate(5424.5,0)"><use data-c="1D450" xlink:href="#MJX-73-TEX-I-1D450"></use></g></g></g></g></g></g></svg>

<figure class="full">
    <img width="700px" src="/static/images/burning_ship1.png">
</figure>

The most interesting part about this one is actually the figure to the left,
which is what the fractal is named after.

<figure class="full">
    <img width="700px" src="/static/images/burning_ship2.png">
</figure>


# Notes on Fractal Computation

I want to talk about some nuances of computing and rendering fractals. As you
would expect, for a full quality render you will need to compute iterations for
every pixel in the image. **<i>This is very computationally expensive.</i>**
Even more troublesome is having to calculate this for *every frame* when
panning around and zooming in if you're writing a realtime explorer.

## Divergence

Let's first define what is meant by "diverge" when iterating over a
z-transform. Mathematically, this means the point transforms off to infinity.
We can discard a point from the set long before infinity though—in fact, for
the three fractals mentioned above, any complex number with a distance from the
origin *greater than 2* will diverge during a z-transform. Storing the square
of this—to prevent having to compute square roots when applying the Pythagorean
theorem—in a `discard_threshold_squared` constant or parameter, we can speed
things up by stopping before unneeded iterations in our compute code:

```c
const int discard_threshold_squared = 4;
```

```c
// [inside z-transform loop]
if ((a*a + b*b) > discard_threshold_squared)
{
    // [store current iteration count for purpose of
    // coloring, indicating point is not in set]
    break;
}
```

Points in the set will not exit the sequence early. An implication of this is
that *the more points in the set the frame contains, the longer the frame will
take to render.*

## Iteration Count

We also need to define a maximum iteration count, the number of iterations it
takes to confidently say "this point does not diverge." This makes for another
design consideration, though. Note in the screenshots above how points closer
to the set are brighter; this means it takes more iterations for those points
to diverge. From this, it should follow that **<i>increasing the maximum number
of iterations will lead to greater detail at the bounds of the set</i>**. If we
set the iteration count too low, we get undetailed renders like the following
(compare to previous screenshot).

<figure class="full">
    <img width="700px" src="/static/images/burning_ship3.png">
</figure>

Not only that, but zooming in only makes the boundary seem coarser. To
compensate for this, I define my maximum iteration count to actually be a
function of zoom level, where `n0` is a "base" iteration count parameter and
`s` is the scale (decreases when zooming in).

<svg xmlns="http://www.w3.org/2000/svg" width="258.972px" height="55.332px" viewBox="0 -1269 9538.8 2038" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" style=""><defs><path id="MJX-125-TEX-I-1D45B" d="M21 287Q22 293 24 303T36 341T56 388T89 425T135 442Q171 442 195 424T225 390T231 369Q231 367 232 367L243 378Q304 442 382 442Q436 442 469 415T503 336T465 179T427 52Q427 26 444 26Q450 26 453 27Q482 32 505 65T540 145Q542 153 560 153Q580 153 580 145Q580 144 576 130Q568 101 554 73T508 17T439 -10Q392 -10 371 17T350 73Q350 92 386 193T423 345Q423 404 379 404H374Q288 404 229 303L222 291L189 157Q156 26 151 16Q138 -11 108 -11Q95 -11 87 -5T76 7T74 17Q74 30 112 180T152 343Q153 348 153 366Q153 405 129 405Q91 405 66 305Q60 285 60 284Q58 278 41 278H27Q21 284 21 287Z"></path><path id="MJX-125-TEX-N-28" d="M94 250Q94 319 104 381T127 488T164 576T202 643T244 695T277 729T302 750H315H319Q333 750 333 741Q333 738 316 720T275 667T226 581T184 443T167 250T184 58T225 -81T274 -167T316 -220T333 -241Q333 -250 318 -250H315H302L274 -226Q180 -141 137 -14T94 250Z"></path><path id="MJX-125-TEX-I-1D460" d="M131 289Q131 321 147 354T203 415T300 442Q362 442 390 415T419 355Q419 323 402 308T364 292Q351 292 340 300T328 326Q328 342 337 354T354 372T367 378Q368 378 368 379Q368 382 361 388T336 399T297 405Q249 405 227 379T204 326Q204 301 223 291T278 274T330 259Q396 230 396 163Q396 135 385 107T352 51T289 7T195 -10Q118 -10 86 19T53 87Q53 126 74 143T118 160Q133 160 146 151T160 120Q160 94 142 76T111 58Q109 57 108 57T107 55Q108 52 115 47T146 34T201 27Q237 27 263 38T301 66T318 97T323 122Q323 150 302 164T254 181T195 196T148 231Q131 256 131 289Z"></path><path id="MJX-125-TEX-N-29" d="M60 749L64 750Q69 750 74 750H86L114 726Q208 641 251 514T294 250Q294 182 284 119T261 12T224 -76T186 -143T145 -194T113 -227T90 -246Q87 -249 86 -250H74Q66 -250 63 -250T58 -247T55 -238Q56 -237 66 -225Q221 -64 221 250T66 725Q56 737 55 738Q55 746 60 749Z"></path><path id="MJX-125-TEX-N-3D" d="M56 347Q56 360 70 367H707Q722 359 722 347Q722 336 708 328L390 327H72Q56 332 56 347ZM56 153Q56 168 72 173H708Q722 163 722 153Q722 140 707 133H70Q56 140 56 153Z"></path><path id="MJX-125-TEX-N-30" d="M96 585Q152 666 249 666Q297 666 345 640T423 548Q460 465 460 320Q460 165 417 83Q397 41 362 16T301 -15T250 -22Q224 -22 198 -16T137 16T82 83Q39 165 39 320Q39 494 96 585ZM321 597Q291 629 250 629Q208 629 178 597Q153 571 145 525T137 333Q137 175 145 125T181 46Q209 16 250 16Q290 16 318 46Q347 76 354 130T362 333Q362 478 354 524T321 597Z"></path><path id="MJX-125-TEX-N-6C" d="M42 46H56Q95 46 103 60V68Q103 77 103 91T103 124T104 167T104 217T104 272T104 329Q104 366 104 407T104 482T104 542T103 586T103 603Q100 622 89 628T44 637H26V660Q26 683 28 683L38 684Q48 685 67 686T104 688Q121 689 141 690T171 693T182 694H185V379Q185 62 186 60Q190 52 198 49Q219 46 247 46H263V0H255L232 1Q209 2 183 2T145 3T107 3T57 1L34 0H26V46H42Z"></path><path id="MJX-125-TEX-N-6F" d="M28 214Q28 309 93 378T250 448Q340 448 405 380T471 215Q471 120 407 55T250 -10Q153 -10 91 57T28 214ZM250 30Q372 30 372 193V225V250Q372 272 371 288T364 326T348 362T317 390T268 410Q263 411 252 411Q222 411 195 399Q152 377 139 338T126 246V226Q126 130 145 91Q177 30 250 30Z"></path><path id="MJX-125-TEX-N-67" d="M329 409Q373 453 429 453Q459 453 472 434T485 396Q485 382 476 371T449 360Q416 360 412 390Q410 404 415 411Q415 412 416 414V415Q388 412 363 393Q355 388 355 386Q355 385 359 381T368 369T379 351T388 325T392 292Q392 230 343 187T222 143Q172 143 123 171Q112 153 112 133Q112 98 138 81Q147 75 155 75T227 73Q311 72 335 67Q396 58 431 26Q470 -13 470 -72Q470 -139 392 -175Q332 -206 250 -206Q167 -206 107 -175Q29 -140 29 -75Q29 -39 50 -15T92 18L103 24Q67 55 67 108Q67 155 96 193Q52 237 52 292Q52 355 102 398T223 442Q274 442 318 416L329 409ZM299 343Q294 371 273 387T221 404Q192 404 171 388T145 343Q142 326 142 292Q142 248 149 227T179 192Q196 182 222 182Q244 182 260 189T283 207T294 227T299 242Q302 258 302 292T299 343ZM403 -75Q403 -50 389 -34T348 -11T299 -2T245 0H218Q151 0 138 -6Q118 -15 107 -34T95 -74Q95 -84 101 -97T122 -127T170 -155T250 -167Q319 -167 361 -139T403 -75Z"></path><path id="MJX-125-TEX-N-32" d="M109 429Q82 429 66 447T50 491Q50 562 103 614T235 666Q326 666 387 610T449 465Q449 422 429 383T381 315T301 241Q265 210 201 149L142 93L218 92Q375 92 385 97Q392 99 409 186V189H449V186Q448 183 436 95T421 3V0H50V19V31Q50 38 56 46T86 81Q115 113 136 137Q145 147 170 174T204 211T233 244T261 278T284 308T305 340T320 369T333 401T340 431T343 464Q343 527 309 573T212 619Q179 619 154 602T119 569T109 550Q109 549 114 549Q132 549 151 535T170 489Q170 464 154 447T109 429Z"></path><path id="MJX-125-TEX-N-2061" d=""></path><path id="MJX-125-TEX-N-2B" d="M56 237T56 250T70 270H369V420L370 570Q380 583 389 583Q402 583 409 568V270H707Q722 262 722 250T707 230H409V-68Q401 -82 391 -82H389H387Q375 -82 369 -68V230H70Q56 237 56 250Z"></path><path id="MJX-125-TEX-N-31" d="M213 578L200 573Q186 568 160 563T102 556H83V602H102Q149 604 189 617T245 641T273 663Q275 666 285 666Q294 666 302 660V361L303 61Q310 54 315 52T339 48T401 46H427V0H416Q395 3 257 3Q121 3 100 0H88V46H114Q136 46 152 46T177 47T193 50T201 52T207 57T213 61V578Z"></path></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mtable"><g data-mml-node="mtr" transform="translate(0,-73)"><g data-mml-node="mtd"><g data-mml-node="mi"><use data-c="1D45B" xlink:href="#MJX-125-TEX-I-1D45B"></use></g><g data-mml-node="mo" transform="translate(600,0)"><use data-c="28" xlink:href="#MJX-125-TEX-N-28"></use></g><g data-mml-node="mi" transform="translate(989,0)"><use data-c="1D460" xlink:href="#MJX-125-TEX-I-1D460"></use></g><g data-mml-node="mo" transform="translate(1458,0)"><use data-c="29" xlink:href="#MJX-125-TEX-N-29"></use></g><g data-mml-node="mo" transform="translate(2124.8,0)"><use data-c="3D" xlink:href="#MJX-125-TEX-N-3D"></use></g><g data-mml-node="msub" transform="translate(3180.6,0)"><g data-mml-node="mi"><use data-c="1D45B" xlink:href="#MJX-125-TEX-I-1D45B"></use></g><g data-mml-node="mn" transform="translate(633,-150) scale(0.707)"><use data-c="30" xlink:href="#MJX-125-TEX-N-30"></use></g></g><g data-mml-node="msub" transform="translate(4383.8,0)"><g data-mml-node="mi"><use data-c="6C" xlink:href="#MJX-125-TEX-N-6C"></use><use data-c="6F" xlink:href="#MJX-125-TEX-N-6F" transform="translate(278,0)"></use><use data-c="67" xlink:href="#MJX-125-TEX-N-67" transform="translate(778,0)"></use></g><g data-mml-node="mn" transform="translate(1311,-241.4) scale(0.707)"><use data-c="32" xlink:href="#MJX-125-TEX-N-32"></use></g></g><g data-mml-node="mo" transform="translate(6098.3,0)"><use data-c="2061" xlink:href="#MJX-125-TEX-N-2061"></use></g><g data-mml-node="mo" transform="translate(6098.3,0)"><use data-c="28" xlink:href="#MJX-125-TEX-N-28"></use></g><g data-mml-node="mn" transform="translate(6487.3,0)"><use data-c="32" xlink:href="#MJX-125-TEX-N-32"></use></g><g data-mml-node="mo" transform="translate(7209.6,0)"><use data-c="2B" xlink:href="#MJX-125-TEX-N-2B"></use></g><g data-mml-node="mfrac" transform="translate(8209.8,0)"><g data-mml-node="mn" transform="translate(220,676)"><use data-c="31" xlink:href="#MJX-125-TEX-N-31"></use></g><g data-mml-node="mi" transform="translate(235.5,-686)"><use data-c="1D460" xlink:href="#MJX-125-TEX-I-1D460"></use></g><rect width="700" height="60" x="120" y="220"></rect></g><g data-mml-node="mo" transform="translate(9149.8,0)"><use data-c="29" xlink:href="#MJX-125-TEX-N-29"></use></g></g></g></g></g></g></svg>

This largely fixes the coarseness of the shape when zooming in, but poses a new
issue. At a certain point when zooming in, the iteration count will become so
large that framerate begins to drop. In the [Rendering on the
GPU](#rendering-on-the-gpu) section I detail a rendering method called
*interlacing* (or *progressive refine*) that lets us split up the work of a
render across multiple frames.

## Floating-Point Precision

The primary limitation with a realtime fractal renderer like this is computer
hardware architecture. For most applications, computers store decimal numbers
according to standard [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) (or
variants thereof), which, in essence, represent decimal numbers in scientific
notation form, comprising a significand ("mantissa") and an exponent. On
modern CPUs and GPUs, there are floating-point arithmetic units (FPUs) built
into hardware that make computation with floating-point types significantly
faster than it would be with a software-only implementation. FPUs nowadays come
in sizes of 16 bits (half-width/FP16), 32 bits (single-width/FP32), 64 bits
(double-width/FP64), and 128 bits (quad-width/FP128). As the names indicate,
more bits means greater precision.

This pertains to computing fractals because the points needed on the complex
plane are decimals, not integers. **<i>Zooming into one point—effectively
increasing the number of decimal places encoded by each pixel's location—only
increases the precision required in computing.</i>**

Limiting ourselves to hardware floating-point implementations caps our
precision at FP128. In reality, if we're running this on the GPU, we're capped
to FP64, since most GPU architectures don't support FP128. (OpenGL's shader
language doesn't even provide a quad-width type, e.g. `long double`. Even for
CPU architectures, hardware support for FP128 is
[iffy](https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_format#Hardware_support).)
Also, since graphics applications generally don't need more than 32 bits of
floating-point precision, GPUs tend to have only 32-bit wide FPUs, with a slow
processing path for FP64 (about 1/64 the speed of FP32 according to some
benchmarks). Despite this, GPUs have significantly more floating-point
execution units than CPUs, so we're *still* running faster on the GPU.

With 64-bit precision on the GPU, we can zoom in by a factor of about 14 times
before we hit our precision limit.

<figure class="full">
    <img width="700px" src="/static/images/fractal_precision.png">
</figure>

This isn't ideal but it's the best I could come up with (or cared to,
considering this was not a planned project) for a realtime renderer. Fractal
dive renderers use high-level CPU software implementations like
[BigFloat](https://github.com/nicowilliams/bigfloat) for arbitrary-precision
floating-point computation, but this would be disastrously slow for a realtime
application (and be incompatible with GPU acceleration).

# Rendering on the GPU

## Using a Fragment Shader

The oversimplified 10,000-foot view of the basic OpenGL rendering pipeline for
an object is as follows:

1. You give the graphics card mesh data and some arbitrary program-defined
   render settings
2. A vertex shader interprets this mesh data as primitive shapes, e.g.
   triangles, with world position data
3. A fragment shader uses the geometry of the primitive each fragment (pixel,
   basically) is attached to and the given arbitrary render settings (including
   textures) to color that fragment
4. The graphics card does some linear algebra magic to combine the computed
   data for all objects into a rendered scene, the framebuffer

<figcaption>This is the explain-like-I'm-five version. If you actually know
OpenGL you know this is so insanely simplified it could just be called "wrong,"
but it's a good enough overview for the purposes of this writeup.</figcaption>

Rather than doing fractal computation on the CPU and loading the result into a
texture, my initial attempt used an OpenGL fragment shader to do computation
entirely on the GPU. It seemed like a good idea; given two triangles filling
the entire screen, the fragment shader is executed for every pixel of the frame
and outputs a color for that pixel. However, there were some drawbacks:

1. Everything was redrawn every frame, even if the user hadn't moved,
   unnecessarily consuming GPU resources
2. This was extraordinarily slow at high iteration counts (high zoom)
3. Iterative refine—either splitting iterations across frames or breaking the
   frame up into chunks—wasn't feasible

Clearly, a different strategy was needed.

## Using a Compute Shader

The [compute shader](https://www.khronos.org/opengl/wiki/Compute_Shader) is
OpenGL's interface for general purpose GPU (GPGPU) programming—analogous to
NVIDIA's CUDA, which lets you use a GPU for arbitrary floating-point-intensive
computation. Compute shaders provide cross-platform support and integrate with
the rest of the graphics library, for things like accessing textures. Perfect!!

As they're meant to be used for GPGPU programming, compute shaders aren't built
into the core OpenGL rendering pipeline. They must be explicitly invoked
(dispatched) separate of the rendering sequence. This is actually great for our
renderer because being able to control when computes happen means we can have
them run only when they're actually needed (when the user pans, zooms, or
transforms).

```cpp
// inside application C++ "world logic"
// once we determine we need to recompute after some user input, we can do it like this:

// bind texture/image to save computed data in
m_pTexture->BindAsImage();

// upload arbitrary data/settings (x/y position, zoom level, screen size, iteration count)
m_pComputeShaderUniformUploader->UploadUniforms(program);

// do compute across the width and height of the screen split up into 32x32 pixel chunks
glDispatchCompute((m_windowWidth+31)/32, (m_windowHeight+31)/32, 1);
```

Splitting up the screen into 32x32 chunks is pretty arbitrary. GPUs are very
heavily designed for parallelism, so, generally, splitting work up into chunks
means things will get done more quickly, but there is an upper limit to this.
In my experimentation, 32x32 chunks seemed to work best for whatever reason.

The compute shader looks like this:

```glsl
#version 460 core

// define the size of the local working group to be 32x32x1
// main() runs every time for each pixel in the 32x32 region
layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

// arbitrary data/settings ("uniforms") uploaded by the application
layout(rgba32f, binding = 0) uniform image2D texture0;
uniform ivec2 screen_size;
uniform dvec2 offset; // indicates x/y position within the fractal
uniform double scale; // decreases when zooming in
uniform float discard_threshold_squared;
uniform int max_iteration_count;

void main()
{
    // 1. convert screen pixel location to world/graph space
    // 2. run z-transform
    // 3. store iteration count into texture
}
```

The only data we're storing in the texture here is a single number per pixel:
the number of iterations it takes for the pixel's corresponding point to
diverge. The same texture is then fed into the fragment shader during the
rendering stage, which reads these values and spits out colors to the screen
accordingly. `-1` can be used to indicate a point that doesn't diverge (in the
set, colored black).

This is great and all, but it doesn't really solve the issue with high
iteration counts slowing things down. When zooming in a lot, the application
becomes so slow that doing anything has a more-than-noticeable input latency
(see this in the video around 0:15). This is where we implement a method for
*progressive refine*.

## Progressive Refine

Progressive refine is the act of taking an intensive piece of work and breaking
it down into multiple chunks *over time*. This is commonly done in dedicated
renderers when you want a preview of a render that will take a while, or in
networking when loading images over a slow connection; it quickly gives you an
image at, for example, 1/64 full quality, then not-so-quickly an image at 1/32,
then 1/16, and so on, with each step taking longer on average than the
previous.  Inspired by a friend's [use of the Bayer matrix for this
purpose](https://jbaker.graphics/writings/bayer.html), I used a similar
**<i>interlacing pattern</i>** defined by the **<i>[Adam7
algorithm](https://en.wikipedia.org/wiki/Adam7_algorithm)</i>**, which splits
work in an 8x8 grid across seven steps:

```glsl
const int ADAM7_MATRIX[8][8] = {
    {1, 6, 4, 6, 2, 6, 4, 6},
    {7, 7, 7, 7, 7, 7, 7, 7},
    {5, 6, 5, 6, 5, 6, 5, 6},
    {7, 7, 7, 7, 7, 7, 7, 7},
    {3, 6, 4, 6, 3, 6, 4, 6},
    {7, 7, 7, 7, 7, 7, 7, 7},
    {5, 6, 5, 6, 5, 6, 5, 6},
    {7, 7, 7, 7, 7, 7, 7, 7},
};
```

<figcaption>For this pattern of interlacing, the 1st and 2nd steps actually
always take the same amount of time because they do the same amount of work.
Every step after that, though, takes twice as long as the
previous.</figcaption>

Incorporating this into the fractal renderer, what we can do is pass some
number to the compute shader which indicates which step we're on (1-7). The
compute shader then indexes the above matrix at the pixel's relative position,
compares that value to the instructed interlace step, and only computes if
the values are equal.

```glsl
uniform int interlace_layer;
```

```glsl
// [in main()]

// 32x32 work group size means we'll have 16 internal 8x8 grids for interlacing.
// Check where the current pixel is within whichever 8x8 grid it falls in:
int relative_pixel_grid_pos_x = gl_LocalInvocationID.x % 8;
int relative_pixel_grid_pos_y = gl_LocalInvocationID.y % 8;

bool do_compute = (ADAM7_MATRIX[relative_pixel_grid_pox_y][relative_pixel_grid_pos_x] == interlace_layer);
if (do_compute)
{
    // z-transform
}
```

For each pixel, the routine then stores either the new computed value or, if
nothing was computed, does nothing. Correspondingly, the fragment shader must
be updated for this behavior as well. Following step 1, most elements in the
texture will still be empty; to prevent the screen from displaying mostly
uncomputed pixels (undefined behavior?), we should check whether a pixel has
been computed before trying to use it, and use the nearest computed pixel if
the first hasn't been.

The resulting behavior is this:

<figure class="full">
    <img width="700px" src="/static/images/fractal_refine.gif">
</figure>

Now, when zooming in at high iteration count, the first compute step is only
doing 1/64 (~1.56%) of the computations it normally would, keeping things
within the span of a single frame, i.e. preventing framerate drops. This is
great for user actions, where zooming and panning happen for as long as the
mouse input lasts—potentially hundreds of frames.

Suppose, though, that a single step takes longer than a frame to compute. Well,
that's no worry either since *compute shaders act independent of the rendering
pipeline*, so rendering is not being held up by a compute shader still running.
Furthermore, to prevent compute dispatches from overlapping, you can make use
of asynchronous OpenGL interfaces like [fences and memory
barriers](https://www.khronos.org/opengl/wiki/Memory_Model) to prevent
dispatching a new compute for the next step until the previous has finished,
framerate unaffected.

My implementation can actually take the idea of progressive refine a step
further, allowing the point's z-transform itself to be distributed across
computes, resulting in *multiple* interlacing passes. It does this by storing
another two elements per pixel in the texture, the real and imaginary
components of the z-transform output, for it to pick up with on the start of
the next compute. This poses the same precision issues as before, however,
considering OpenGL textures only allow you to store elements up to FP32
precision, so it doesn't work very well at high zoom levels. We can work around
this by using a separate texture with four elements per pixel: two 32-bit
elements for the real component, and two more 32-bit elements for the imaginary
component. See
[floatBitsToInt](https://registry.khronos.org/OpenGL-Refpages/gl4/html/floatBitsToInt.xhtml)
and related GLSL functions for a way you might accomplish this.

