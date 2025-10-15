// --- Librerías ---
import processing.video.*;
import gab.opencv.*;
import oscP5.*;
import netP5.*;

// --- Variables principales ---
Capture camara;
OpenCV opencv;
PImage mascaraMovimiento;
boolean hayMovimiento = false;

// --- OSC ---
OscP5 oscP5;
NetAddress destino;

// --- Configuración ---
int umbralDeMovimiento = 1000; 
boolean estadoAnterior = false; // para enviar solo si cambia

void setup() {
  size(640, 480);
  
  // Inicializar cámara
  camara = new Capture(this, 640, 480);
  camara.start();
  
  // Inicializar OpenCV
  opencv = new OpenCV(this, 640, 480);
  opencv.startBackgroundSubtraction(5, 3, 0.5);
  
  // Inicializar OSC
  oscP5 = new OscP5(this, 12000); // Puerto local (solo si querés recibir)
  destino = new NetAddress("127.0.0.1", 9000); // IP y puerto del receptor (Unity)
}

void draw() {
  if (camara.available()) camara.read();
  
  opencv.loadImage(camara);
  opencv.updateBackground();
  
  mascaraMovimiento = opencv.getOutput();
  
  mascaraMovimiento.loadPixels();
  int pixelesBlancos = 0;

  for (int i = 0; i < mascaraMovimiento.pixels.length; i++) {
    if (mascaraMovimiento.pixels[i] == color(255)) {
      pixelesBlancos++;
    }
  }

  hayMovimiento = pixelesBlancos > umbralDeMovimiento;

  // Dibujar cámara y estado
  image(camara, 0, 0);
  
  noStroke();
  fill(hayMovimiento ? color(255, 0, 0) : color(0, 255, 0));
  ellipse(width/2, height/2, 100, 100);
  
  tint(255, 100);
  image(mascaraMovimiento, 0, 0);
  noTint();
  
  // Enviar por OSC solo si cambió el estado
  if (hayMovimiento != estadoAnterior) {
    OscMessage mensaje = new OscMessage("/movimiento");
    mensaje.add(hayMovimiento ? 1 : 0);
    oscP5.send(mensaje, destino);
    println("Enviado a Unity: " + (hayMovimiento ? "Movimiento detectado" : "Sin movimiento"));
    estadoAnterior = hayMovimiento;
  }
}
