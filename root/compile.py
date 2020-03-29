#!/usr/bin/env python3
"""Open source template engine for compilation of the static joshstock.in"""

import sys
import os
import shutil
import json
import markdown2
import readtime


def file_read(filename: str):
    """Read text from file by filename"""
    try:
        with open(filename, "r") as file:
            return file.read()
    except FileNotFoundError:
        print(f"[file_read] '{filename}' not found. exiting...")
        exit(1)
    except Exception as error:
        print(f"[file_read] error while trying to read from '{filename}':")
        print(error)
        print("[file_read] exiting...")
        exit(1)


def file_write(filename: str, text: str):
    """Write text to file by filename"""
    try:
        with open(filename, "w") as file:
            file.write(text)
    except Exception as error:
        print(f"[file_write] error while trying to write to '{filename}':")
        print(error)
        print("[file_write] exiting...")
        exit(1)


def directory_empty(path: str):
    """Clear file directory by path"""
    for file in os.listdir(path):
        filepath = os.path.join(path, file)
        try:
            if os.path.isfile(filepath):
                os.unlink(filepath)
            elif os.path.isdir(filepath):
                shutil.rmtree(filepath)
        except Exception as error:
            print(f"[directory_empty] error while trying to empty directory {path}:")
            print(error)
            print("[directory_empty] exiting...")
            exit(1)


ROUTEMAP = {}
TEMPLATES = {}


def template_fill(template_string: str, template_keys: dict):
    """Fills in all template key placeholders in template_string"""
    global TEMPLATES
    return_string = template_string
    did_fill = False
    for key in template_keys:
        if f"${key}" in return_string:
            return_string = return_string.replace(f"${key}", template_keys[key])
            did_fill = True
    for key in TEMPLATES:
        if f"${key}" in return_string:
            return_string = return_string.replace(f"${key}", TEMPLATES[key])
            did_fill = True
    if did_fill:
        return_string = template_fill(return_string, template_keys)
    return return_string


def templates_load(templates_config: dict):
    """Preload templates from their files"""
    templates = {}
    for temp in templates_config:
        print(f"[templates_load] loading template '{temp}'")
        templates[temp] = file_read(templates_config[temp])
    return templates


def template(output_path: str):
    """The main template engine to generate the site's static content"""
    global TEMPLATES
    global ROUTEMAP
    print("[template] emptying working directory")
    directory_empty(output_path)

    print("[template] reading config file at ./config.json")
    config = json.loads(file_read("config.json"))

    print("[template] copying static directory")
    output_file = os.path.join(output_path, "static")
    shutil.copytree(config["static_directory"], output_file)

    print("[template] loading templates from config")
    TEMPLATES = templates_load(config["templates"])

    print("[template] running blog article generator")
    blog_article_listings = ""
    for article in config["articles"]:
        article_url = f"/blog/{article['identifier']}"
        print(f"[template/blog] creating article '{article['title']}' at {article_url}")

        content = markdown2.markdown(file_read(article["markdown"]))
        content_time = str(readtime.of_html(content))

        # Create a new listing for the blog archive page
        blog_article_listings += template_fill(
            TEMPLATES["blog-listing"],
            {
                "title": article["title"],
                "datestring": article["datestring"],
                "readtime": content_time,
                "banner": article["banner"],
                "description": article["description"],
                "permalink": article_url,
            },
        )

        # Create blog article from template
        blog_article = template_fill(
            TEMPLATES["blog-article"],
            {
                "title": article["title"],
                "datestring": article["datestring"],
                "readtime": content_time,
                "banner": article["banner"],
                "description": article["description"],
                "permalink": article_url,
                "content": content,
            },
        )
        output_file = os.path.join(output_path, f"blog-{article['identifier']}.html")
        file_write(output_file, blog_article)
        ROUTEMAP[f"{config['domain']}{article_url}"] = 0.7

    TEMPLATES["@blog-listings"] = blog_article_listings

    print("[template] running page generator")
    for page in config["pages"]:
        page_url = page["location"]
        print(f"[template/page] creating page '{page['title']}' at {page_url}")
        content = template_fill(
            file_read(page["file"]),
            {
                "title": page["title"],
                "description": page["description"],
                "permalink": page_url,
            },
        )
        output_file = os.path.join(output_path, page["destination"])
        file_write(output_file, content)
        ROUTEMAP[f"{config['domain']}{page_url}"] = page["priority"]

    print("[template] copying custom static files")
    for copy in config["copy"]:
        print(f"[template/copy] copying file '{copy['file']}' to '{copy['location']}'")
        output_file = os.path.join(output_path, copy["location"])
        shutil.copy(copy["file"], output_file)

    print("[template] compiling sitemap XML")
    sitemap = TEMPLATES["sitemap"]
    for route in ROUTEMAP:
        sitemap += (
            f"<url><loc>{route}</loc><priority>{ROUTEMAP[route]}</priority></url>"
        )
    sitemap += "</urlset>"
    output_file = os.path.join(output_path, "sitemap.xml")
    file_write(output_file, sitemap)

    print("[template] finished")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        FOLDER_OUT = "/var/www/html"
    else:
        FOLDER_OUT = sys.argv[1]
    print(f"[main] compile.py starting")
    print(f"[main] changing active directory to script location")
    os.chdir(sys.path[0])
    if not os.path.isdir(FOLDER_OUT):
        print(f"[main] {FOLDER_OUT} is not a valid folder location. exiting...")
        exit(1)
    OUTPUT_PATH = os.path.abspath(FOLDER_OUT)
    print(f"[main] output path set to {OUTPUT_PATH}")
    print(f"[main] running template engine routine")
    template(OUTPUT_PATH)
    print(f"[main] finished. exiting...")
    exit(0)
else:
    print(f"[main] script is not __main__. exiting...")
    exit(1)
