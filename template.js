// The dot that goes in between header elements is &#x2022;
var header = `
    <header>
        <nav style="text-align: center">
        </nav>
    </header>`

var toggleDarkButton = `
        <button onclick="toggleDarkMode()" type="button" id="dark-mode-button"></button>
        `


var footer = `
    <footer>` + toggleDarkButton + `
        <button onclick="toggleMainDiv()" type="button" id="hide-button">&#x25B2;</button>
    </footer>`

if (document.getElementById('header')) {
    document.getElementById('header').innerHTML = header;
}

if (document.getElementById('footer')) {
    document.getElementById('footer').innerHTML = footer;
}

if (document.getElementById('toggleDarkButton')) {
    document.getElementById('toggleDarkButton').innerHTML = toggleDarkButton;
}

function toggleMainDiv() {
    var main = document.getElementById('main');
    var hide_button = document.getElementById('hide-button');
    if (main.style.display === "none") {
        if (document.getElementById('header')) {
            document.getElementById('header').style.display = "block";
        }
        main.style.display = "block";
        hide_button.innerHTML = "&#x25B2;"
    } else {
        if (document.getElementById('header')) {
            document.getElementById('header').style.display = "none";
        }
        main.style.display = "none";
        hide_button.innerHTML = "&#x25BC;"
    }
}

function toggleDarkMode() {
    var containerClasses = document.body.classList;
    if (containerClasses.contains('dark-mode')) {
        containerClasses.remove('dark-mode');
        document.getElementById('dark-mode-button').innerHTML = "Dark mode";
    } else {
        containerClasses.add('dark-mode');
        document.getElementById('dark-mode-button').innerHTML = "Light mode";
    }
}

toggleDarkMode();
