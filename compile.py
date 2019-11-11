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
		print(filename + " not found. exitting")
		exit(1)
	except:
		print("can't open " + filename + " for reading. exitting")
		exit(1)

def writefile(filename, text):
	try:
		with open(filename, "w") as file:
			file.write(text)
			file.close()
	except:
		print("can't open " + filename + " for writing. exitting")
		exit(1)

def main():
	config = json.loads(readfile("config.json"))
	print("creating blog articles")
	listings = ""
	article_listing_template = readfile(config["templates"]["blog-archive-listing"])
	article_template = readfile(config["templates"]["blog-article"])
	blog_css = readfile(config["templates"]["blog-css"])
	for article in config["articles"]:
		print("creating article \"" + article["title"] + "\"")
		articlehtml = "" + article_template
		articlehtml = articlehtml.replace("$css", blog_css)
		articlehtml = articlehtml.replace("$title", article["title"])
		articlehtml = articlehtml.replace("$date", article["date"])
		articlehtml = articlehtml.replace("$banner", article["banner"])
		articlehtml = articlehtml.replace("$content", readfile(article["content"]))
		articlehtml = articlehtml.replace("$copyright", config["copyright"])
		link = article["title"].lower().replace(" ", "-")+".html"
		articlehtml = articlehtml.replace("$permalink", link)
		writefile(os.path.join(out_path, link), articlehtml)
		listinghtml = "" + article_listing_template
		listinghtml = listinghtml.replace("$title", article["title"])
		listinghtml = listinghtml.replace("$date", article["date"])
		listinghtml = listinghtml.replace("$banner", article["banner"])
		listinghtml = listinghtml.replace("$summary", article["summary"])
		listinghtml = listinghtml.replace("$permalink", link)
		listings = listinghtml + listings
	print("creating blog archive")
	archive_template = readfile(config["templates"]["blog-archive"])
	archive_template = archive_template.replace("$css", blog_css)
	archive_template = archive_template.replace("$articles", listings)
	archive_template = archive_template.replace("$copyright", config["copyright"])
	writefile(os.path.join(out_path, "blog.html"), archive_template)
	print("creating landing")
	landing = readfile(config["templates"]["landing"])
	writefile(os.path.join(out_path, "index.html"), landing)

if __name__ == "__main__":
	if len(sys.argv) < 2:
		print("usage: compile.py <folder>")
		exit(1)
	folder_out = sys.argv[1]
	print("compile.py starting")
	if not os.path.isdir(folder_out):
		print(folder_out + " is not a valid folder location. exitting")
		exit(1)
	out_path = os.path.abspath(folder_out)
	print("output set to " + out_path)
	print("beginning main routine")
	main()
	print("finished")
