#!/usr/bin/env python3

import sys
import os
import json

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

routemaps = {}
def routemap(route, file):
	routemaps[route] = file

def main():
	config = json.loads(readfile("config.json"))

	# Index
	print("creating landing")
	landing = readfile(config["templates"]["landing"])
	file = os.path.join(out_path, "index.html")
	writefile(file, landing)
	routemap("/", file)

	# Privacy
	print("creating privacy policy page")
	privacy = readfile(config["templates"]["privacy"])
	file = os.path.join(out_path, "privacy.html")
	writefile(file, privacy)
	routemap("/privacy", file)

	# /blog*
	print("creating blog articles")
	listings = ""
	article_listing_template = readfile(config["templates"]["blog-archive-listing"])
	article_template = readfile(config["templates"]["blog-article"])
	blog_css = readfile(config["templates"]["blog-css"])

	for article in config["articles"]:
		# Create article
		print("creating article \"" + article["title"] + "\"")
		articlehtml = "" + article_template
		articlehtml = articlehtml.replace("$css", blog_css)
		articlehtml = articlehtml.replace("$title", article["title"])
		articlehtml = articlehtml.replace("$date", article["date"])
		articlehtml = articlehtml.replace("$banner", article["banner"])
		articlehtml = articlehtml.replace("$content", readfile(article["content"]))
		articlehtml = articlehtml.replace("$copyright", config["copyright"])
		file = os.path.join(out_path, "blog-"+article["title"].lower().replace(" ", "-")+".html")
		path = "/blog/"+article["title"].lower().replace(" ", "-")
		articlehtml = articlehtml.replace("$permalink", path)
		writefile(file, articlehtml)
		routemap(path, file)

		# Update archive listings
		listinghtml = "" + article_listing_template
		listinghtml = listinghtml.replace("$title", article["title"])
		listinghtml = listinghtml.replace("$date", article["date"])
		listinghtml = listinghtml.replace("$banner", article["banner"])
		listinghtml = listinghtml.replace("$summary", article["summary"])
		listinghtml = listinghtml.replace("$permalink", path)
		listings = listinghtml + listings

	# Blog archive
	print("creating blog archive")
	archive_template = readfile(config["templates"]["blog-archive"])
	archive_template = archive_template.replace("$css", blog_css)
	archive_template = archive_template.replace("$articles", listings)
	archive_template = archive_template.replace("$copyright", config["copyright"])
	file = os.path.join(out_path, "blog.html")
	writefile(file, archive_template)
	routemap("/blog", file)

	# Error 404
	print("creating 404 error page")
	e404 = readfile(config["templates"]["404"])
	file = os.path.join(out_path, "error-404.html")
	writefile(file, e404)

	# Routemap config
	print("Routemap:")
	for map in routemaps:
		print(map)

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print("usage: compile.py <folder>")
		exit(1)
	folder_out = sys.argv[1]
	print("compile.py starting")
	if not os.path.isdir(folder_out):
		print(folder_out + " is not a valid folder location. exiting")
		exit(1)
	out_path = os.path.abspath(folder_out)
	print("output set to " + out_path)
	print("beginning main routine")
	main()
	print("finished")
