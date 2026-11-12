# 🎵 SerenatiAr — La Rockola Digital con IA

> **"No más flores... ¡vamos a SerenatiAr!"**

**SerenatiAr** es una aplicación web interactiva impulsada por IA donde el usuario graba un estribillo con su voz (15 segundos) y nuestro motor neuronal afina su voz a nivel profesional (**Voice-to-Voice RVC**) y reemplaza su rostro en un videoclip de estudio (**Face-Swap**), convirtiéndolo en la estrella de su propia serenata en menos de 3 minutos.

---

## 🚀 Estado del Proyecto: Fase 1 (MVP Rockola & Puerta Falsa)

- **Estética Visual:** Inspirada en *Tommy Hilfiger* (Azul Marino Profundo `#060D1E`, Rojo Escarlata `#E11D2A` y Crema `#F7F5F0`) fusionada con una **Rockola / Vitrola de los 80s** con Glassmorphism, botones mecánicos 3D e inclinación 3D animada con GSAP ScrollTrigger.
- **Economía Gamificada por Monedas:** Botón mecánico de *"Insertar Moneda"* con efectos de sonido sintetizados en tiempo real mediante **Web Audio API** (sin dependencias de archivos MP3 externos).
- **Onboarding de Vibra (Type-Beats 100% Royalty-Free):**
  - `A1` — Romance 90s (Bolero Pop)
  - `B2` — Urbano Suave (Acústico)
  - `C3` — Pop Latino (Balada)
  - `D4` — Tradicional (Nuestra Tierra)
- **Estrategia "Puerta Falsa" (Validación de Mercado):** Captura de leads otorgando **3 Monedas Gratis (valoradas en $4.99 USD)** al completar el flujo de prueba de grabación de 15 segundos.

## 🛠️ Stack Tecnológico

- **Frontend (Fase 1):** HTML5, Tailwind CSS, Vanilla JS, GSAP 3 (ScrollTrigger), Lucide Icons, Web Audio API.
- **Backend & DB (Fase 3):** Supabase (PostgreSQL) para Usuarios, Billeteras de Monedas e Historial de Serenatas.
- **Inferencia IA (Serverless GPU):** Fal.ai / RunPod / Replicate (RVC Voice-to-Voice + InsightFace).
- **Pagos LATAM (Fase 4):** Wompi / ePayco (Nequi, PSE, Efecty).

## 💻 Ejecución en Local

```bash
python -m http.server 8080
```
Luego abre `http://localhost:8080` en tu navegador.
