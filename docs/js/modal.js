const modal = document.getElementById('modal');
const modalContent = document.getElementById('modal-content');
const modalImage = document.getElementById('modal-image');

window.onclick = (e) => {
    if (event.target == modal || event.target == modalImage || event.target == modalContent) {
        modal.style.display = "none";
    }
}

function openModal(e) {
    let src = e.src;
    if (window.matchMedia("screen").matches && screen.width <= 800) {
        window.open(src, "_self");
        return;
    }
    modal.style.display = "block";
    modalImage.src = src;
}

// When page loads, add an `onclick` that opens the modal to every img tag.
window.addEventListener("DOMContentLoaded", function() {
    const galleryImgs = document.querySelectorAll('.gallery img');
    for (const img of galleryImgs) {
        img.onclick = function () { openModal(this) };
    }
});

