# librerias
import cv2
import mediapipe as mp
import numpy as np
from pythonosc.udp_client import SimpleUDPClient

# osc configuracion
OSC_IP = "127.0.0.1"
OSC_PUERTO = 7000
cliente = SimpleUDPClient(OSC_IP, OSC_PUERTO)

# mediapipe
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.6, min_tracking_confidence=0.6)
mp_dibujo = mp.solutions.drawing_utils

# camara
camara = cv2.VideoCapture(0)
camara.set(3, 640)
camara.set(4, 480)

#variables
puntos_previos = None
umbral_mov = 0.002  # sensibilidad del movimiento
dist_min, dist_max = 0.10, 0.35  # calibración de cercanía
umbral_desactivado = 1.15  # distancia para “apagar” los ojos

print("Sistema activo")

while True:
    ok, imagen = camara.read()
    if not ok:
        continue
    img_rgb = cv2.cvtColor(imagen, cv2.COLOR_BGR2RGB)
    resultados = pose.process(img_rgb)

    # variables por frame
    presencia = 0
    cercania = 0
    zona = -1
    movimiento = False
    ojo_izq = ojo_der = False

    if resultados.pose_landmarks:
        presencia = 1
        puntos = resultados.pose_landmarks.landmark
        hombro_izq, hombro_der = puntos[11], puntos[12]

        # aolo si ambos hombros son visibles
        if hombro_izq.visibility > 0.6 and hombro_der.visibility > 0.6:
            cx = (hombro_izq.x + hombro_der.x) / 2
            zona = 0 if cx < 0.5 else 1

            # calcular cercanía
            dist = abs(hombro_izq.x - hombro_der.x)
            cercania = (dist - dist_min) / (dist_max - dist_min)

            # apagar “ojos” si está muy cerca
            if cx < 0.5 and cercania > umbral_desactivado:
                ojo_izq = True
            if cx >= 0.5 and cercania > umbral_desactivado:
                ojo_der = True

        # detección de movimiento
        if puntos_previos is not None:
            cambios = [
                np.linalg.norm(np.array([p.x, p.y]) - np.array([a.x, a.y]))
                for p, a in zip(puntos, puntos_previos)
                if p.visibility > 0.6
            ]
            if cambios:
                if np.mean(cambios) > umbral_mov:
                    movimiento = True

        puntos_previos = puntos
        mp_dibujo.draw_landmarks(imagen, resultados.pose_landmarks, mp_pose.POSE_CONNECTIONS)

    # osc datos enviandose
    cliente.send_message("/presencia", presencia)
    cliente.send_message("/zona", zona)
    cliente.send_message("/cercania", float(cercania))
    cliente.send_message("/movimiento", int(movimiento))
    cliente.send_message("/ojoIzqDesactivado", int(ojo_izq))
    cliente.send_message("/ojoDerDesactivado", int(ojo_der))

    # feedback 
    texto = "No hay silueta detectada"
    color = (255, 255, 255)
    if presencia:
        if ojo_izq:
            texto, color = "Ojo IZQUIERDO desactivado", (0, 255, 255)
        elif ojo_der:
            texto, color = "Ojo DERECHO desactivado", (0, 255, 255)
        elif movimiento:
            texto, color = "Hay movimiento", (0, 255, 0)
        else:
            texto, color = "No hay movimiento", (0, 0, 255)

    cv2.putText(imagen, texto, (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 3)
    cv2.putText(imagen, f"Cercania: {cercania:.2f}", (20, 100), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200,200,200), 2)
    cv2.putText(imagen, f"Zona: {'Izquierda' if zona==0 else 'Derecha' if zona==1 else '-'}",
                (20, 130), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200,200,200), 2)
    cv2.line(imagen, (320, 0), (320, 480), (255,255,255), 1)

    # ventana
    cv2.imshow("Ojos Vigilantes", imagen)
    if cv2.waitKey(1) & 0xFF == 27: 
        break

camara.release()
cv2.destroyAllWindows()
print("chauuuu")
