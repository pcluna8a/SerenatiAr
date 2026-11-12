# 🎬 Fase 2: Biblia de Producción de Assets ("El Secreto" Técnico y Legal)

Este documento define las especificaciones exactas de ingeniería de audio y dirección de video para **SerenatiAr**. Nuestra arquitectura **"Assets-First"** evita el uso de canciones con copyright y evita la generación lenta/costosa de Text-to-Video desde cero, logrando:
1. **Cero riesgo legal (100% Royalty-Free).**
2. **Procesamiento GPU Serverless < 3 minutos.**
3. **Margen bruto operativo del 88%** ($0.17 USD costo Audio Pro / $0.60 USD costo Video Pro).

---

## 1. Arquitectura de Audio: Los 12 "Type-Beats" + Vocal Guides

Para que el motor **RVC (Retrieval-based Voice Conversion v2)** funcione sin que el usuario tenga que ser cantante profesional, usamos un esquema de **Doble Stem por Canal (15 segundos exactos a 48kHz / 24-bit WAV)**:

1. **`[CODIGO]_instrumental.wav`**: Pista instrumental masterizada sin voz principal, dejando un "bolsillo" de frecuencias entre `300Hz` y `3.5kHz` para que la voz afinada encaje perfectamente.
2. **`[CODIGO]_vocal_guide.wav`**: Voz de un cantante de sesión real (o guía vocal limpia sin reverb) cantando la melodía exacta del estribillo de 15 segundos.
   * **Truco de Ingeniería RVC:** El usuario graba 15 segundos con su voz (incluso si desafina un poco). Nuestro pipeline extrae el timbre/identidad vocal (embeddings HuBERT/RVC) de la grabación del usuario y lo transfiere sobre la afinación perfecta del `vocal_guide.wav` (o aplica Auto-Pitch + RVC directo sobre la toma del usuario si el usuario cantó en tiempo).

### Estructura de Carpetas de Audio
```text
assets/
├── catalog.json                 # Manifiesto maestro de los 12 canales (Lados A, B y C)
├── audio/
│   └── watermark-serenatiar.mp3 # Marca de agua sonora ("Creado con SerenatiAr") para el tier Freemium
├── previews/
│   ├── A1_preview.mp3           # Preview corto (8s, 128kbps) para la Rockola
│   └── ... (A1 a C4)
└── stems/
    ├── A1_instrumental.wav      # Instrumental limpio (15s)
    ├── A1_vocal_guide.wav       # Guía vocal afinada (15s)
    └── ... (A1 a C4)
```

---

## 2. Arquitectura de Video: Plantillas Maestras de Estudio (Esqueletos de Movimiento)

En lugar de generar video con IA desde cero (que deforma manos, micrófonos e instrumentos y cuesta >$2.50 USD por clip), grabamos **12 Plantillas Maestras de 15 segundos** en formato vertical (`9:16`, `1080x1920`, `30fps`, `H.264 High Profile`).

### Reglas de Rodaje para Compatibilidad 99.9% con InsightFace / LivePortrait:
1. **Ángulo del Actor de Estudio:** El rostro del actor debe mantenerse dentro de un ángulo de `±30°` respecto a la cámara durante los 15 segundos (sin giros de perfil completo de 90°).
2. **Obstrucción Cero del Rostro (Regla del Micrófono):**
   * El micrófono vintage cromado debe ubicarse ligeramente por debajo del mentón (`10–15 cm` abajo y a `15°` lateral), **nunca tapando la boca ni la nariz**. Esto evita que el algoritmo de Face-Swap parpadee al cruzar el micrófono.
   * No usar gafas oscuras ni sombreros de ala baja que proyecten sombra dura sobre las cejas.
3. **Iluminación del Set (Estética Tommy Hilfiger):**
   * **Key Light (Luz Principal):** Luz suave frontal-lateral a `45°` (`4500K` neutra/cálida) que ilumine uniformemente ambos pómulos.
   * **Rim Light (Contraluz):** Neón **Rojo Escarlata (`#E11D2A`)** a un lado y **Azul Marino Profundo (`#0A1633`)** en el fondo para identidad visual inmediata en TikTok/Reels.
4. **Flujo del "Character Sheet" del Usuario (3 Selfies):**
   * La interfaz solicita al usuario 3 fotos: **1. Frontal neutra**, **2. Sonriendo ligeramente**, **3. Ángulo 3/4 (45°)**.
   * El backend promedia el embedding facial de las 3 imágenes con `InsightFace (buffalo_l)` y ejecuta el reemplazo de rostro + restauración facial (`GFPGAN / CodeFormer` a `0.5` de peso) sobre la plantilla maestra `TPL-[CODIGO].mp4`.

---

## 3. Matriz de los 12 Canales Oficiales (Lados A, B y C)

| Canal | Lado | Título | Subgénero | BPM | Tonalidad | Plantilla de Video Asociada |
| :--- | :---: | :--- | :--- | :---: | :---: | :--- |
| **A1** | Lado A | Romance 90s | Bolero Pop Orquestal | 76 | C Major | `TPL-A1-BOLERO` |
| **A2** | Lado A | Balada Estadio | Piano & Cuerdas Épicas | 72 | G Major | `TPL-A2-BALADA` |
| **A3** | Lado A | Bachata Sensual | Guitarra Requinto & Bongó | 124 | A Minor | `TPL-A3-BACHATA` |
| **A4** | Lado A | Vallenato Lírico | Acordeón Romántico | 84 | D Major | `TPL-A4-VALLENATO` |
| **B1** | Lado B | Urbano Suave | Reggaetón Lento Acústico | 88 | F Minor | `TPL-B1-URBANO` |
| **B2** | Lado B | Afrobeat Latino | Groove Caribe & R&B | 100 | E Minor | `TPL-B2-AFRO` |
| **B3** | Lado B | Pop Folk Band | Guitarras & Banjos | 116 | C Major | `TPL-B3-POPBAND` |
| **B4** | Lado B | Tropipop Fiesta | Merengue & Acordeón Pop | 128 | A Major | `TPL-B4-FIESTA` |
| **C1** | Lado C | Mariachi de Gala | Ranchera Imperial | 82 | G Major | `TPL-C1-MARIACHI` |
| **C2** | Lado C | Popular / Cantina | Requinto & Despecho | 90 | D Minor | `TPL-C2-POPULAR` |
| **C3** | Lado C | Salsa Romántica | Piano Montuno & Bronces | 94 | C Minor | `TPL-C3-SALSA` |
| **C4** | Lado C | Sierreño / Tumbado | Docerola & Tololoche | 108 | E Minor | `TPL-C4-TUMBADO` |
