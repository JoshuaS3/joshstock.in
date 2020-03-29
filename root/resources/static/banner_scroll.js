let blog_center = document.getElementsByClassName("blog-center")[0];
let headers = blog_center.getElementsByTagName("h2");
for (let i = 0; i < headers.length; i++) {
	let header = headers[i];
	let inner = header.innerHTML;
	let id = inner.replace(/[^a-z0-9]/gi,"-").toLowerCase();
	header.id = id;
	header.innerHTML = "<a href=\"#" + id + "\">" + inner + "</a>";
};
let blog_banner = document.getElementsByClassName("blog-banner")[0];
function scroll() {
	blog_banner.style["background-position"] = "50% " + (50 - (window.scrollY/20)).toString() + "%";
};
scroll();
