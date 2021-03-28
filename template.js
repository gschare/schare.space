var header = `
    <header>
        <nav style="text-align: center">
            <a href="/index.html">Home</a> &#x2022;
            <a href="/about.html">About</a> &#x2022;
            <a href="/teaching.html">Teaching</a> &#x2022;
            <a href="https://github.com/gschare">GitHub</a>
        </nav>
    </header>`

var footer = `
    <footer>
        <hr>
        <p>We're off you know...</p>
        <button onclick="toggleDarkMode()" type="button" id="dark-mode-button"></button>
    </footer>`

document.getElementById('header').innerHTML = header;
document.getElementById('footer').innerHTML = footer;

function toggleDarkMode() {
    var containerClasses = document.getElementById('container').classList;
    if (containerClasses.contains('dark-mode')) {
        containerClasses.remove('dark-mode');
        document.getElementById('dark-mode-button').innerHTML = "Dark mode";
    } else {
        containerClasses.add('dark-mode');
        document.getElementById('dark-mode-button').innerHTML = "Light mode";
    }
}

toggleDarkMode();
