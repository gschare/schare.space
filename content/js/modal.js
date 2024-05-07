let modal = document.getElementById('modal');

let modalImage = document.getElementById('modal-image');

window.onclick = (e) => {
    if (event.target == modal || event.target == modalImage) {
        modal.style.display = "none";
    }
}

function openModal(e) {
  let src = e.src;
  modal.style.display = "block";
  modalImage.src = src;
}
