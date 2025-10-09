import processing.video.*;
import gab.opencv.*;

Capture camara;
OpenCV opencv;
PImage mascaraMovimiento;

boolean hayMovimiento = false;
int umbral = 4; // sensibilidad al movimiento

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
  
  // calcular cantidad de movimiento
  mascaraMovimiento.loadPixels();
  float suma = 0;
  for (int i = 0; i < mascaraMovimiento.pixels.length; i++) {
    suma += brightness(mascaraMovimiento.pixels[i]);
  }
  float promedio = suma / mascaraMovimiento.pixels.length;
  
  hayMovimiento = promedio > umbral;
  
  // mostrar cámara
  image(camara, 0, 0);
  
  // alerta que cambia de color
  noStroke();
  if (hayMovimiento) {
    fill(255, 0, 0); // rojo = movimiento
  } else {
    fill(0, 255, 0); // verde = sinmovimiento
  }
  ellipse(width/2, height/2, 100, 100);
  
  // superponer máscara de movimiento
  tint(255, 100);
  image(mascaraMovimiento, 0, 0);
  noTint();
}
