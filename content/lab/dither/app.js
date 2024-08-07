function dither(file) {
  const dropzone = document.getElementById("dropzone");
  const url = URL.createObjectURL(file);
  dropzone.innerHTML = `<img id="image" src="${url}">`;
  
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  const img = document.createElement('img');
  img.setAttribute('src', url);
  img.onload = () => { /* say "thank you ChatGPT!" */
      const width = document.getElementById('width-slider').value;
      const height = width * (img.height / img.width);
      canvas.setAttribute('width', width);
      canvas.setAttribute('height', height);
      context.drawImage(img, 0, 0, width, height);
      const imgData = context.getImageData(0, 0, width, height);

      const newData = monochrome(imgData, 'floydsteinberg', 0.5);
      context.putImageData(newData, 0, 0);

      const ditheredUrl = canvas.toDataURL('image/png');

      const dithered = document.getElementById("dithered");
      dithered.innerHTML = `<img src="${ditheredUrl}">`;
  }
}

function dropHandler(ev) {
  console.log("File(s) dropped");

  // Prevent default behavior (Prevent file from being opened)
  ev.preventDefault();

  if (ev.dataTransfer.items) {
    // Use DataTransferItemList interface to access the file(s)
    [...ev.dataTransfer.items].forEach((item, i) => {
      // If dropped items aren't files, reject them
      if (item.kind === "file") {
        const file = item.getAsFile();
        console.log(`… file[${i}].name = ${file.name}`);

        dither(file);
      }
    });
  } else {
    // Use DataTransfer interface to access the file(s)
    [...ev.dataTransfer.files].forEach((file, i) => {
      console.log(`… file[${i}].name = ${file.name}`);
    });
  }
}

function dragOverHandler(ev) {
  console.log("File(s) in drop zone");

  // Prevent default behavior (Prevent file from being opened)
  ev.preventDefault();
}

window.onload = (e) => {
    const slider = document.getElementById('width-slider');
    const result = document.getElementById('width-result');
    slider.addEventListener('input', (e) => {
       if (result.value == e.target.value) {
           return;
       }
       result.value = e.target.value;
    });

    result.addEventListener('input', (e) => {
       if (slider.value == e.target.value) {
           return;
       }
       slider.value = e.target.value;
    });
}
