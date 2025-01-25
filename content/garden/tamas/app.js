let timers = {};

function fadeOut(tag) {
    if (timers[tag.id]) {
        clearTimeout(timers[tag.id]);
    }
    const volume = tag.volume;
    const interval = 30;
    const step = 0.01;
    const timer = setTimeout(function tick() {
        if (tag.volume <= step) {
            tag.pause();
            tag.currentTime = 0;
            tag.volume = volume;
        } else {
            tag.volume -= step; 
            timers[tag.id] = setTimeout(tick, interval);
        }
    }, interval);
    timers[tag.id] = timer;
}

function playAudio(tag) {
    const theaudio = tag.querySelector('audio');
    document.querySelectorAll('audio').forEach(a => {
        if (a != theaudio) {
            fadeOut(a);
        }
    });
    if (timers[theaudio.id]) {
        clearTimeout(timers[theaudio.id]);
    }
    theaudio.volume = 0.1;
    theaudio.play();
}

function pauseAudio(tag) {
    fadeOut(tag.querySelector('audio'));
}

document.addEventListener("DOMContentLoaded", () => {
    const video1 = document.getElementById("crossfade-from");
    const video2 = document.getElementById("crossfade-to");

    let currentVideo = video1;
    let nextVideo = video2;

    const fadeBeforeEnd = 0.539;

    // Initialize the first video as visible
    currentVideo.classList.add("visible");
    nextVideo.classList.add("hidden");

    function crossFade() {
        // Swap the visibility of the two videos
        nextVideo.currentTime = 0.539; // Reset the next video
        nextVideo.play();

        nextVideo.classList.remove("hidden");
        nextVideo.classList.add("visible");

        // Swap current and next references
        [currentVideo, nextVideo] = [nextVideo, currentVideo];
        setTimeout(() => {nextVideo.classList.remove("visible"); nextVideo.classList.add("hidden");}, 539);
    }

    function handleTimeUpdate() {
        if (currentVideo.duration - currentVideo.currentTime <= fadeBeforeEnd) {
          currentVideo.removeEventListener("timeupdate", handleTimeUpdate); // Avoid multiple triggers
          crossFade();
      
          // Reattach the timeupdate listener for the new current video
          currentVideo.addEventListener("timeupdate", handleTimeUpdate);
        }
    }

    // Listen for when the current video ends
    currentVideo.addEventListener("timeupdate", handleTimeUpdate);

    // Adjust for auto-looping
    video1.loop = false;
    video2.loop = false;
});