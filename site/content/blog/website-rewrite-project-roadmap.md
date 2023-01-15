---
type: article
identifier: website-rewrite-project-roadmap
title: Website rewrite / project roadmap
description: Finally, a decent and (hopefully) low-maintenance website.
datestring: 2023-01-14
banner_image: /static/images/river2.jpg
links:
    Source: https://git.joshstock.in/joshstock.in
    resty-gitweb: https://git.joshstock.in/resty-gitweb
---

I've redesigned the website (again) and rewritten the [template
engine](https://git.joshstock.in/joshstock.in) (again).  Now that the template
engine encompasses the whole subdomain, it'll be easier to generate consistent
content. HTML is generated exclusively through Python, which allows a ton of
flexibility; it runs Sass for stylesheets and uses Markdown for content, which
I can attach metadata to in the head of the `.md` file. For example, this blog
article content is written in Markdown with this meta-header:

```yaml
---
type: article
identifier: website-rewrite-project-roadmap
title: Website rewrite / project roadmap
description: Finally, a decent and (hopefully) low-maintenance website.
datestring: 2023-01-14
banner_image: /static/images/river2.jpg
links:
    Source: https://git.joshstock.in/joshstock.in
    resty-gitweb: https://git.joshstock.in/resty-gitweb
---
```

I can also write HTML in the Markdown, which lets me nicely embed media in
`figure`s, as seen below.

I'll do a better writeup on the template engine in the [Projects](/projects)
section someday.

<figure class="float-left heading-aligned">
    <video class="medium" src="/static/videos/river.mp4" controls></video>
    <figcaption>river.mp4: Kankakee River State Park. Example embedded media.</figcaption>
</figure>

## Roadmap

There are still a few things I need to fix or add to the site—in particular:

- Update [resty-gitweb](https://git.joshstock.in/resty-gitweb) so I can use
  this site's generated headers as templates on the Git subdomain, for seamless
  cross-subdomain appearance
- **Populate the blog and projects pages!**

On populating the blog, here is a list of **planned articles**:
- Patching Python's regex AST for confusable homoglyphs
- Recovering a Linux desktop with a misconfigured shell
- Upgrading an end-of-life (EOL) Ubuntu version using apt
- Building nginx With OpenResty
- Installing and Configuring [resty-gitweb](https://git.joshstock.in/resty-gitweb) for Production
- Using ESP32 to Read PWM or PPM Data
- Automating AutoCAD environment setup with AutoLISP

And on populating the **projects** page:
- [espy](https://www.youtube.com/watch?v=lfSqagByDVk) — a remote controlled snow plow
- [s3-bsync](https://git.joshstock.in/s3-bsync) — asynchronous bidirectional file syncing with AWS S3
- co2-monitor — ESP32-based carbon dioxide (CO2) monitoring and analytics IoT platform
- [resty-gitweb](https://git.joshstock.in/resty-gitweb) — an HTTP interface for Git built with OpenResty
- [ncurses-minesweeper](https://git.joshstock.in/ncurses-minesweeper) — terminal emulator minesweeper clone
- [joshstock.in](https://git.joshstock.in/joshstock.in) — this website
- zydeco — planned future OpenGL project; breaking into graphics programming, procedural generation, geology and climate simulation, mesh optimization
- [UIUC SE101B](https://www.youtube.com/watch?v=0e011eOmPh0) — reverse engineering and design project for SE101 @ UIUC Grainger
- RCHS STEM — port old ePortfolio and pictures

Here's the full Kanboard project for this website:

<iframe class="full" src="https://kanboard.joshstock.in/?controller=BoardViewController&action=readonly&token=3a343d4fa775266f953482d9dc6a8ce7c6fe299a0490653024a74ee85a8d"></iframe>

As much as I want to work on these projects, I am however a full-time
engineering student interning during summers and, while I try my best, I can't
commit any regular amount of time to writing or working on these projects.
