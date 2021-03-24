var header = `
    <header>
        <nav style="text-align: center">
            <a href="/home.html">Home</a> &#x2022;
            <a href="/about.html">About</a> &#x2022;
            <a href="/teaching.html">Teaching</a> &#x2022;
            <a href="https://github.com/gschare">GitHub</a>
        </nav>
    </header>`

var footer = `
    <footer>
        <hr>
        <p>Why are you <em>here</em>?</p>
    </footer>`

document.getElementById("header").innerHTML = header;
document.getElementById("footer").innerHTML = footer;
