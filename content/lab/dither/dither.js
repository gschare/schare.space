/*global self:true*/

// Atkinson thanks to https://github.com/ticky/canvas-dither/blob/master/canvas-image-worker.js
// Flickr's Atkinson was easy to understand but melted with some fps https://github.com/flickr/FlickrDithr/blob/master/dither.js
// Bayer parsed from http://en.wikipedia.org/wiki/Ordered_dithering

// var bayerMap = [
//   [  1,  9,  3, 11 ],
//   [ 13,  5, 15,  7 ],
//   [  4, 12,  2, 10 ],
//   [ 16,  8, 14,  6 ]
// ];

var bayerThresholdMap = [
  [  15, 135,  45, 165 ],
  [ 195,  75, 225, 105 ],
  [  60, 180,  30, 150 ],
  [ 240, 120, 210,  90 ]
];

var lumR = [];
var lumG = [];
var lumB = [];
for (var i=0; i<256; i++) {
  lumR[i] = i*0.299;
  lumG[i] = i*0.587;
  lumB[i] = i*0.114;
}

function hexToRgb(hex) {
      // Remove the '#' character if it exists
      hex = hex.replace(/^#/, '');

      // Convert 3-digit hex to 6-digit hex if necessary
      if (hex.length === 3) {
        hex = hex.split('').map(char => char + char).join('');
      }

      // Parse the hex string into RGB values
      const bigint = parseInt(hex, 16);
      const r = (bigint >> 16) & 255;
      const g = (bigint >> 8) & 255;
      const b = bigint & 255;

      return [r, g, b];
}

function monochrome(imageData, threshold, type, blackHex, whiteHex){

  const blackColor = hexToRgb(blackHex);
  const whiteColor = hexToRgb(whiteHex);

  var imageDataLength = imageData.data.length;

  // Greyscale luminance (sets r pixels to luminance of rgb)
  for (var i = 0; i <= imageDataLength; i += 4) {
    imageData.data[i] = Math.floor(lumR[imageData.data[i]] + lumG[imageData.data[i+1]] + lumB[imageData.data[i+2]]);
  }

  var w = imageData.width;
  var newPixel, err;

  for (var currentPixel = 0; currentPixel <= imageDataLength; currentPixel+=4) {

    if (type === "none") {
      // No dithering
      imageData.data[currentPixel] = imageData.data[currentPixel] < threshold ? 0 : 255;
    } else if (type === "bayer") {
      // 4x4 Bayer ordered dithering algorithm
      var x = currentPixel/4 % w;
      var y = Math.floor(currentPixel/4 / w);
      var map = Math.floor( (imageData.data[currentPixel] + bayerThresholdMap[x%4][y%4]) / 2 );
      imageData.data[currentPixel] = (map < threshold) ? 0 : 255;
    } else if (type === "floydsteinberg") {
      // Floyd–Steinberg dithering algorithm
      newPixel = imageData.data[currentPixel] < 129 ? 0 : 255;
      err = Math.floor((imageData.data[currentPixel] - newPixel) / 16);
      imageData.data[currentPixel] = newPixel;

      imageData.data[currentPixel       + 4 ] += err*7;
      imageData.data[currentPixel + 4*w - 4 ] += err*3;
      imageData.data[currentPixel + 4*w     ] += err*5;
      imageData.data[currentPixel + 4*w + 4 ] += err*1;
    } else {
      // Bill Atkinson's dithering algorithm
      newPixel = imageData.data[currentPixel] < 129 ? 0 : 255;
      err = Math.floor((imageData.data[currentPixel] - newPixel) / 8);
      imageData.data[currentPixel] = newPixel;

      imageData.data[currentPixel       + 4 ] += err;
      imageData.data[currentPixel       + 8 ] += err;
      imageData.data[currentPixel + 4*w - 4 ] += err;
      imageData.data[currentPixel + 4*w     ] += err;
      imageData.data[currentPixel + 4*w + 4 ] += err;
      imageData.data[currentPixel + 8*w     ] += err;
    }

    // Set g and b pixels equal to r
    imageData.data[currentPixel + 1] = imageData.data[currentPixel + 2] = imageData.data[currentPixel];
  }
  
  // change every pixel to the right colors
  for (var currentPixel = 0; currentPixel <= imageDataLength; currentPixel+=4) {
      const r = imageData.data[currentPixel];
      if (r === 0) {
          imageData.data[currentPixel] = blackColor[0];
          imageData.data[currentPixel+1] = blackColor[1];
          imageData.data[currentPixel+2] = blackColor[2];
      } else if (r === 255) {
          imageData.data[currentPixel] = whiteColor[0];
          imageData.data[currentPixel+1] = whiteColor[1];
          imageData.data[currentPixel+2] = whiteColor[2];
      }
  }

  return imageData;
}
