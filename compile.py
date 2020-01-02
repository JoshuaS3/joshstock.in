#!/usr/bin/env python3

import sys
import os
import shutil
import json
import re

def readfile(filename):
	try:
		with open(filename, "r") as file:
			s = file.read()
			file.close()
			return s
	except FileNotFoundError:
		print(filename + " not found. exiting")
		exit(1)
	except:
		print("can't open " + filename + " for reading. exiting")
		exit(1)

def writefile(filename, text):
	try:
		with open(filename, "w") as file:
			file.write(text)
			file.close()
	except:
		print("can't open " + filename + " for writing. exiting")
		exit(1)

def empty_dir(path):
	for file in os.listdir(path):
		filepath = os.path.join(path, file)
		try:
			if os.path.isfile(filepath):
				os.unlink(filepath)
			elif os.path.isdir(filepath):
				shutil.rmtree(filepath)
		except Exception as e:
			print("error while trying to empty working directory")
			print(e)
			exit(1)

routemaps = {}
sitemap = """<?xml version="1.0" encoding="UTF-8"?>
<urlset
	  xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
		http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">"""
def routemap(route, priority=0.5):
	routemaps[route] = True
	global sitemap
	sitemap += "<url><loc>https://joshstock.in" + route + "</loc><priority>" + str(priority) + "</priority></url>"

def main():
	print("emptying working directory")
	empty_dir(out_path)

	print("reading config")
	config = json.loads(readfile("config.json"))

	# Static
	print("copying static")
	shutil.copytree(config["static"], os.path.join(out_path, "static"))

	# Favicon
	print("copying favicon")
	shutil.copy(config["templates"]["favicon"], os.path.join(out_path, "favicon.ico"))

	# Index
	print("creating landing")
	landing = readfile(config["templates"]["landing"])
	file = os.path.join(out_path, "index.html")
	writefile(file, landing)
	routemap("/", 1.0)

	# CSS
	print("copying CSS source")
	blog_css = readfile(config["templates"]["blog-css"])
	file = os.path.join(out_path, "blog.css")
	writefile(file, blog_css)

	# Privacy
	print("creating privacy policy page")
	privacy = readfile(config["templates"]["privacy"])
	privacy = privacy.replace("$copyright", config["copyright"])
	file = os.path.join(out_path, "privacy.html")
	writefile(file, privacy)
	routemap("/privacy", 0.5)

	# /blog*
	print("creating blog articles")
	listings = ""
	article_listing_template = readfile(config["templates"]["blog-archive-listing"])
	article_template = readfile(config["templates"]["blog-article"])

	for article in config["articles"]:
		# Create article
		print("creating article \"" + article["title"] + "\"")
		titleFixed = re.sub("[^A-Za-z0-9]", "-", article["title"].lower())
		path = "/blog/"+titleFixed

		# Update archive listings
		listinghtml = "" + article_listing_template
		listinghtml = listinghtml.replace("$title", article["title"])
		listinghtml = listinghtml.replace("$date", article["date"])
		listinghtml = listinghtml.replace("$banner", article["banner"])
		listinghtml = listinghtml.replace("$summary", article["summary"])
		sections = ""
		if "sections" in article:
			sections = "<ol style=\"list-style-type:auto; padding-left:20px\"><b>Contents</b>"
			for section in article["sections"]:
				sectionTag = re.sub("[^A-Za-z0-9]", "-", section).lower()
				sections += "<li><a href=\"" + path + "#" + sectionTag + "\">" + section + "</a></li>"
			sections += "</ol>"
		listinghtml = listinghtml.replace("$sections", sections)
		listinghtml = listinghtml.replace("$permalink", path)
		listings = listinghtml + listings

		articlehtml = "" + article_template
		articlehtml = articlehtml.replace("$title", article["title"])
		articlehtml = articlehtml.replace("$date", article["date"])
		articlehtml = articlehtml.replace("$banner", article["banner"])
		articlehtml = articlehtml.replace("$content", readfile(article["content"]))
		articlehtml = articlehtml.replace("$summary", article["summary"])
		articlehtml = articlehtml.replace("$sections", sections)
		articlehtml = articlehtml.replace("$copyright", config["copyright"])
		file = os.path.join(out_path, "blog-"+titleFixed+".html")
		articlehtml = articlehtml.replace("$permalink", path)
		writefile(file, articlehtml)
		routemap(path, 0.7)


	# Blog archive
	print("creating blog archive")
	archive_template = readfile(config["templates"]["blog-archive"])
	archive_template = archive_template.replace("$articles", listings)
	archive_template = archive_template.replace("$copyright", config["copyright"])
	file = os.path.join(out_path, "blog.html")
	writefile(file, archive_template)
	routemap("/blog", 0.9)

	# Error 404
	print("creating 404 error page")
	e404 = readfile(config["templates"]["404"])
	file = os.path.join(out_path, "error-404.html")
	writefile(file, e404)

	# Routemap config
	print("writing sitemap to sitemap.xml")
	global sitemap
	sitemap += "</urlset>"
	writefile(os.path.join(out_path, "sitemap.xml"), sitemap)

if __name__ == "__main__":
	if len(sys.argv) < 2:
		folder_out = "/var/www/html"
	else:
		folder_out = sys.argv[1]
	print("compile.py starting")
	print("changing active directory to script location")
	os.chdir(sys.path[0])
	if not os.path.isdir(folder_out):
		print(folder_out + " is not a valid folder location. exiting")
		exit(1)
	out_path = os.path.abspath(folder_out)
	print("output set to " + out_path)
	print("beginning main routine")
	main()
	print("finished")
