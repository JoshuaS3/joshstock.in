function updateTheme() {
    if (localStorage.getItem("theme") == null) {
        if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
            console.log("Prefers dark");
            localStorage.setItem("theme", "dark")
        } else {
            localStorage.setItem("theme", "")
        }
    }
    let themeName = localStorage.getItem("theme");

    document.querySelector("html").classList.value = themeName;
}

function toggleDarkMode() {
    localStorage.setItem("theme", localStorage.getItem("theme") == "" ? "dark" : "");
    updateTheme();
}

updateTheme();
document.addEventListener('DOMContentLoaded', updateTheme);
