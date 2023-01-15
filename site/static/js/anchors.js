function createAnchors() {
    let headers = document.querySelectorAll("#links, #comments, .blog-content h1, .content-body h2, .content-body h3, .content-body h4, .content-body h5, .content-body h6");
    for (header of headers) {
        let id = header.id;
        if (id == "") continue;
        header.classList.add("header")
        let anchor = document.createElement("a")
        anchor.classList.value = "anchor"
        anchor.href = "#" + id
        let svg = document.createElement("img")
        svg.src = "/static/svg/link.svg"
        svg.classList.value = "svg icon"
        anchor.appendChild(svg)
        header.appendChild(anchor)
    }
}

document.addEventListener('DOMContentLoaded', createAnchors);
