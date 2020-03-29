I've always wanted a little website I could use as a general portfolio and showcase for my hobby projects. Granted it's not a lot of stuff at the moment, there still are things I'd like to take the time to explain in a more orderly fashion. This website isn't anything special; it's just something I can use to organize my thoughts, projects, and files.

This article serves a few purposes. Namely, it documents my process of creating this website (and the method of using [my compiler for it](https://github.com/JoshuaS3/joshstock.in)) and provides step-by-step details for anyone who would like to follow suit. It also helps populates my blog page as I currently don't have anything else to publish.

## Design

There are a few things I wanted from the start in a website:

* A simple landing page and blog system
* Statically hosted, with no backend
* A way to push to production from Git
* An easy way to compile multiple separate pages with shared components
* An easy way to add new pages/articles

Most of these technical requirements are for ease of use on my end. As it currently stands, I'm able to make changes on my machine, test them by compiling and using nginx on localhost, and finally use Git to push to my box and compile the repository into production assets. In general, I believed it easier and faster to create and implement each of these mechanics on my own than rely on a framework like [Hugo](https://gohugo.io) and take the time to learn another framework.

Sending each request to a backend for processing is unnecessary in the case of a small blog like this. While I'd love to use something like WordPress, it's overkill for what I'm trying to do here. Serving pages statically is also safer; the lack of a backend for REST requests eliminates almost any opportunity to hack or exploit the site. At the moment, the only ways to hack the site are to either take over the box entirely or to attempt to exploit the nginx configuration, both being nearly impossible.

## Creating Site Templates

I first began drafting some simple asset templates I knew would be reused across the website. I wrote a basic outline for the blog article and blog archive pages, the shared CSS style for them, and the HTML for individual article listings on the archive page. These were created as templates the compiler script could splice data into. I settled on the `$` character to indicate template keys. You can see this in the templates for article listings and their place in the blog archive:

<div class="block"><script src="https://gist.github.com/JoshuaS3/be6d66aca08f986f3f98074d56dc5168.js"></script></div>

Other pages employ similar techniques for other trivial variables. For example, the footer is represented by the `footer` key, preceded by `$`. When written, it is automatically expanded by the template engine:

$footer

Wherever something is repeated, there's probably a template key for it.

## Writing the Compiler

(All website resources and compiler code and configuration can be found in the [GitHub repository](https://github.com/JoshuaS3/joshstock.in).)

I decided to write the compiler script in Python because it's nearly universal and comes equipped with multiple modules for filesystem manipulation. It also handles strings with ease.

To record metadata alternative to hardcoding it into the compiler, I first created a JSON configuration file and populated it with some variables. In the end there's no "correct" way to do this and it ultimately relies on whatever the developer believes to be most efficient or convenient schema. Here's the compiler configuration for this website at the time of writing this article:

<div class="block"><script src="https://gist.github.com/JoshuaS3/7191765aff7c36244092c7aa40aa58d1.js"></script></div>

Everything here appears to be self explanatory. The `static` key points to the location of the `resources/static` folder. Key-value pairs of the `templates` dictionary provide names to the file paths of file templates. The `articles` list contains dictionaries of metadata for each blog article.

Because each template key is indicated clearly and uniquely in each file, the compiler can simply read the template file, replace the template keys with their respective values, and write the final output. See the following snippet:

<div class="block"><script src="https://gist.github.com/JoshuaS3/1f6b93ac5a8a4652b3346ece1c79f7f7.js"></script></div>

There are a few things happening here. First, the working (production) directory is cleared of files using a separate utility function. Next, the configuration file is read and parsed into the `config` variable. After that, the `static/` folder is copied to the working directory, and the landing and privacy policy pages are created.

When the privacy page is created, the builtin `str.replace` function is used to replace the template key with its corresponding value. Nothing fancy here. This continues for the rest of the script, substituting text and writing output files.

For blog articles, I iterate through the list in the configuration file and use the blog article template to create new `blog-*.html` files in the working directory. As such, this page can also be indexed using `/blog-creating-my-website-stack.html`. Internal redirection will be covered in the nginx configuration file.

(For search engine optimization, I pass each route through a `routemap` function which generates the sitemap.xml containing each location and its priority.)

Running the full file generates the site contents and dispenses them in the indicated directory.

<div class="block"><img class="blog-img-full" src="/static/site-compile.png"/></div>

<div class="block"><img class="blog-img-full" src="/static/site-compiled.png"/></div>

## Serving Webpages

Before I made this site, I'd never used nginx or Apache—or really any "real" webserver apart from express.js—so this was a learning experience for me. I followed some tutorials found online on the installation and configuration of nginx. After many hours trying to configure it, I got this server configuration to work the best (heavily commented for convenience):

<div class="block"><script src="https://gist.github.com/JoshuaS3/14742cc812d69be428bd6baf3239895d.js"></script></div>

This server is configured to redirect all `http` requests (port 80) to `https` (port 443) and any requests to the `www` subdomain to the non-www root domain, where requests are fulfilled. Of course, while this works for my website, it won't work for everything. If there are more or less or different pages to serve than I have, the `location` blocks should be changed accordingly. If the server doesn't have a TLS certificate to use for HTTPS connections, it should only `listen` on port 80 without the `ssl` and `http2` directives.

## Automatic Deployment into Production

I currently do all site development on my own machine and push to my box which acts as a production server. This was done by initiating a bare Git repository on my server and adding it as a remote ("`production`") on my local. From my local, I can run `git push production master` to push my code to the server. In the Git repository on my server, I have a custom `post-receive` hook that checks out the `master` branch into a different directory and runs `compile.py` on `/var/www/html` (the nginx server's static files folder).

<div class="block"><img class="blog-img-full" src="/static/site-push.png"/></div>

There's a great tutorial on GitHub Gist that explains the process in detail: [Simple automated GIT Deployment using GIT Hooks](https://gist.github.com/noelboss/3fe13927025b89757f8fb12e9066f2fa)

## Publishing the Website

After using Git to push to the server and running the compile script, the server will begin serving static web pages as long as nginx is running. From this point, new pages or articles can be created and the compile script modified at any time. The hook in the server's Git repository automatically compiles the static pages into production.

Beyond here, everything is just frontend development.

In the future, I'll continue writing blog articles detailing my projects and pursuits. I might create a separate directory of pages showcasing my projects as part of a portfolio. I also plan on creating a subdomain with dynamic file hosting. Until then, [I have other projects to work on](https://github.com/JoshuaS3).
