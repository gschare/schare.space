<title>Garden</title>
<nav class="secondary">
[Meta](what.html)
&centerdot;
[Research](research.html)
&centerdot;
[More](more.html)
&centerdot;
[IC](ic.html)
&centerdot;
[Logs](logs.html)
</nav>
# Garden

> "Cela est bien dit, répondit Candide, mais il faut cultiver notre jardin."

[Voltaire, _Candide_]{.cite}

<footer><a id="hatch" href="/lab/"><hr id="hatch-line"><div id="hatch-text-container">[Hatch to Secret Lab]{#hatch-text}</div></a></footer>

<style>
#hatch {
    position: relative;
    height: 1lh;
    width: 100%;
    display: block;
}

@media (hover: none) {
  #hatch:focus:not(:active) {
    pointer-events: none; /* Block navigation on first tap */
  }
}

#hatch-line {
    border: none;
    height: 2px;
    background: var(--fg-light-secondary);
    position: absolute;
    top: 2px;
    width: 100%;
    transition: transform 0.6s linear 0.4s;
    transform: scaleY(1);
    transform-origin: center;
}

.dark-mode #hatch-line {
    background: var(--fg-dark-secondary);
}

#hatch:hover #hatch-line,
#hatch:active #hatch-line,
#hatch:focus #hatch-line {
    transform: scaleY(5);
    transition-delay: 0s;
}

#hatch-line::after {
    /* hack to make the background appearing and disappearing animated */
    content: "";
    position: absolute;
    inset: 0;
    background: repeat-x url("/assets/img/lab/hatch.jpg");
    background-size: 30%;
    opacity: 0;
    transition: opacity 0.1s linear 0.9s;
}

#hatch:hover #hatch-line::after,
#hatch:active #hatch-line::after,
#hatch:focus #hatch-line::after {
    opacity: 1;
    transition-delay: 0s;
}

/* Order of operations:
 *  line changes background 0.2s
 *  line grows 0.6s
 *  hatch opens revealing text 0.4s
 * and symmetrically in reverse.
 */

#hatch-text-container {
    /*margin: auto 15px;*/
    padding: 0 8px;
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    display: block;
    font-weight: bold;
    background: var(--bg-light);
    clip-path: inset(0 50% 0 50%);
    transition: clip-path 0.4s linear 0s;
}

.dark-mode #hatch-text-container {
    background: var(--bg-dark);
}

#hatch:hover #hatch-text-container,
#hatch:active #hatch-text-container,
#hatch:focus #hatch-text-container {
    clip-path: inset(0 0 0 0);
    transition-delay: 0.6s;
}

#hatch-text {
    color: black;
    font-size: 110%;
}
.dark-mode #hatch-text {
    color: #fbd011;
}
</style>
