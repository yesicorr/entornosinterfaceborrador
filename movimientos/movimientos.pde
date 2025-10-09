import processing.video.*;
import gab.opencv.*;

Capture camara;
OpenCV opencv;
PImage mascaraMovimiento;
boolean hayMovimiento = false;

int umbralDeMovimiento = 1000; 

void setup() {
  size(640, 480);
  camara = new Capture(this, 640, 480);
  camara.start();
  
  opencv = new OpenCV(this, 640, 480);
  opencv.startBackgroundSubtraction(5, 3, 0.5);
}

void draw() {
  if (camara.available()) camara.read();
  
  opencv.loadImage(camara);
  opencv.updateBackground();
  
  mascaraMovimiento = opencv.getOutput();
  
  mascaraMovimiento.loadPixels();
  int pixelesBlancos = 0; //debe reiniciar en cada fotograma

  for (int i = 0; i < mascaraMovimiento.pixels.length; i++) {
    if (mascaraMovimiento.pixels[i] == color(255)) {
      pixelesBlancos++;
    }
  }

  hayMovimiento = pixelesBlancos > umbralDeMovimiento;

  image(camara, 0, 0);
  
  noStroke();
  if (hayMovimiento) {
    fill(255, 0, 0); // Rojo
  } else {
    fill(0, 255, 0); // Verde
  }
  ellipse(width/2, height/2, 100, 100);
  
  tint(255, 100);
  image(mascaraMovimiento, 0, 0);
  noTint();
}
