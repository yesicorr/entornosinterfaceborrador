// --- Librerías ---
import processing.video.*;
import gab.opencv.*;
import oscP5.*;
import netP5.*;

// --- Variables principales ---
Capture camara;
OpenCV opencv;
PImage mascaraMovimiento;

// --- Estados de los ojos ---
boolean ojoIzqActivo = false;
boolean ojoDerActivo = false;
boolean ojoIzqMuerto = false;
boolean ojoDerMuerto = false;

// --- Comunicación OSC ---
OscP5 osc;
NetAddress destino;

// --- Configuración de detección ---
int umbralMovimiento = 1000;   // Sensibilidad del movimiento
int umbralCercania = 70000;    // Qué tan cerca debe estar para “matar” un ojo

// --- Contadores ---
int pixelesIzq = 0;
int pixelesDer = 0;

void setup() {
  size(640, 480);
  
  // Iniciar cámara
  camara = new Capture(this, 640, 480);
  camara.start();
  
  // Iniciar OpenCV
  opencv = new OpenCV(this, 640, 480);
  opencv.startBackgroundSubtraction(5, 3, 0.5);
  
  // Iniciar conexión con Unity (OSC)
  osc = new OscP5(this, 12000);
  destino = new NetAddress("127.0.0.1", 9000);
  

}

void draw() {
  if (camara.available()) camara.read();
  
  // Actualizar la imagen
  opencv.loadImage(camara);
  opencv.updateBackground();
  mascaraMovimiento = opencv.getOutput();
  mascaraMovimiento.loadPixels();
  
  // Reiniciar contadores
  pixelesIzq = 0;
  pixelesDer = 0;
  
  // Contar pixeles blancos (movimiento)
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int i = x + y * width;
      if (mascaraMovimiento.pixels[i] == color(255)) {
        if (x < width/2) pixelesIzq++;
        else pixelesDer++;
      }
    }
  }

  // Solo analizar si el ojo no está muerto
  if (!ojoIzqMuerto) {
    ojoIzqActivo = pixelesIzq > umbralMovimiento;
    if (pixelesIzq > umbralCercania) ojoIzqMuerto = true;
  }

  if (!ojoDerMuerto) {
    ojoDerActivo = pixelesDer > umbralMovimiento;
    if (pixelesDer > umbralCercania) ojoDerMuerto = true;
  }

  // Dibujar cámara de fondo
  image(camara, 0, 0);

  // Dibujar zonas (izquierda / derecha)
  noStroke();
  
  // IZQUIERDA
  if (ojoIzqMuerto) fill(0, 0, 0);           // negro = muerto
  else if (ojoIzqActivo) fill(255, 0, 0);      // Rojo = movimiento
  else fill(0, 255, 0);                        // Verde = sin movimiento
  rect(0, 0, width/2, height);
  
  // DERECHA
  if (ojoDerMuerto) fill(0, 0, 0);
  else if (ojoDerActivo) fill(255, 0, 0);
  else fill(0, 255, 0);
  rect(width/2, 0, width/2, height);
  
  // Enviar datos por OSC
  enviarDatos();

  // Mostrar datos en pantalla
  fill(255);
  textSize(18);
  text("Pixeles Izq: " + pixelesIzq, 20, 30);
  text("Pixeles Der: " + pixelesDer, width/2 + 20, 30);
  text("Umbral Cercanía: " + umbralCercania, 20, height - 20);

  // Mostrar máscara de movimiento encima
  tint(255, 100);
  image(mascaraMovimiento, 0, 0);
  noTint();
}

// --- Enviar datos a Unity ---
void enviarDatos() {
  OscMessage msgIzq = new OscMessage("/ojoIzq");
  msgIzq.add(ojoIzqMuerto ? 0 : (ojoIzqActivo ? 1 : 0));
  osc.send(msgIzq, destino);
  
  OscMessage msgDer = new OscMessage("/ojoDer");
  msgDer.add(ojoDerMuerto ? 0 : (ojoDerActivo ? 1 : 0));
  osc.send(msgDer, destino);
}

//apretar espacio revive a los ojos / a la obra
void keyPressed() {
  if (key == ' ') {
    ojoIzqMuerto = false;
    ojoDerMuerto = false;
    println("ojos revividos");
  }
}
