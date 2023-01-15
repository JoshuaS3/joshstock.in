let banner = document.getElementsByClassName("banner-image")[0];
function scroll() {
	banner.style["background-position"] = "50% " + (30 - (document.body.scrollTop/18)).toString() + "%";
};
scroll();
