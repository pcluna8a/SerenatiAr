# FASE 5: AUDITORÍA QA MÓVIL, UNIT ECONOMICS Y ESTRATEGIA DE LANZAMIENTO (GTM)

Este documento consolida el cierre de ingeniería (**Fase 5**) de **SerenatiAr**, incluyendo la auditoría de calidad (QA), la matemática de rentabilidad neta por región PPP y el plan de ataque comercial **B2C Viral + B2B Comercios Aliados**.

---

## 1. Matriz de Auditoría QA (100% Verificada)

| Componente / Flujo | Estado | Verificación Técnica |
| :--- | :---: | :--- |
| **Estética & Rockola 80s (Tommy Hilfiger Palette)** | ✅ APROBADO | Alto contraste (`#060D1E`, `#E11D2A`, `#F7F5F0`), inclinación 3D GSAP ScrollTrigger (`rotateX(10deg)` → `0deg`) y botonera táctil. |
| **Regla "Solo Canción" por Defecto (Audio-First)** | ✅ APROBADO | `includeVideoMode = false` por defecto (`🎵 Solo Canción - 1 🪙`). El panel de 3 selfies y video 9:16 permanece oculto hasta que el usuario solicita `🎬 + Videoclip IA (3 🪙)`. |
| **Catálogo Cultural Geolocalizado (12 Type-Beats)** | ✅ APROBADO | 4 Regiones (`LATAM`, `NA_UK`, `EUROPE`, `ASIA`) + Cajón interactivo `🌍 Explorar ritmos del mundo` y previsualización armónica Web Audio API. |
| **Base de Datos Cloud en Supabase (`vlmmuflegeirbcmrsuul`)** | ✅ APROBADO | Tablas `mvp_leads`, `paquetes_recarga` (15 paquetes PPP), `catalogo_pistas_geo` (12 pistas), `billetera_usuarios`, `transacciones_monedas` e `historial_serenatas` con RLS y funciones ACID. |
| **Candado Freemium & Marca de Agua Auditiva** | ✅ APROBADO | Reproductor Master superpone marca de agua acústica cada 3s hasta invertir `1 🪙` (Audio) o `3 🪙` (Video), habilitando descarga `.WAV` real (44.1kHz) y envío por WhatsApp. |
| **Pasarela Multi-Región PPP & Libro Mayor** | ✅ APROBADO | Adaptación dinámica de métodos locales (**Nequi / PSE / Bancolombia / Efecty** en Colombia; **SPEI / OXXO** en México; **Apple Pay / Google Pay / Stripe** en USA, Europa y Asia). |
| **PWA Mobile-First + Dedicatorias por URL & QR B2B** | ✅ APROBADO | Barra móvil fija inferior (`< md`), `manifest.webmanifest`, etiquetas OpenGraph para WhatsApp y lectura automática de parámetros `?para=...&de=...&track=...` + Generador de Tarjeta QR para Floristerías. |

---

## 2. Unit Economics y Rentabilidad Neta por Paquete (PPP)

Costo estimado de infraestructura Serverless GPU (Fal.ai / RunPod Spot):
* **1 Audio RVC (`1 🪙`):** ~\$0.015 USD de cómputo GPU (6 segundos en RTX 4090).
* **1 Videoclip Face-Swap + Audio (`3 🪙`):** ~\$0.09 USD de cómputo GPU (~\$0.03 USD por moneda consumida).

| Región PPP | Paquete Estrella (Plata: 10 🪙) | Precio de Venta | Comisión Pasarela (~3.5% + fijo) | Costo GPU Máximo (10 🪙) | **Margen Neto Estimado** |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **🇨🇴 Tier 3 (`LATAM_COP`)** | Plata (9 + 1 Bonus) | \$25.000 COP (~\$6.25 USD) | ~\$0.35 USD (Wompi/PSE) | ~\$0.30 USD | **\$5.60 USD (~89%)** |
| **🇲🇽 Tier 3 (`LATAM_MXN`)** | Plata (9 + 1 Bonus) | \$129 MXN (~\$6.45 USD) | ~\$0.40 USD (MercadoPago) | ~\$0.30 USD | **\$5.75 USD (~89%)** |
| **🇺🇸 Tier 1 (`NA_USD`)** | Plata (9 + 1 Bonus) | \$12.99 USD | ~\$0.68 USD (Stripe) | ~\$0.30 USD | **\$12.01 USD (~92%)** |
| **🇪🇺 Tier 2 (`EU_EUR`)** | Plata (9 + 1 Bonus) | €10.99 EUR (~\$11.80 USD) | ~\$0.55 USD (Stripe EU) | ~\$0.30 USD | **\$10.95 USD (~92%)** |
| **🌏 Tier 4 (`EMERGING_USD`)**| Plata (9 + 1 Bonus) | \$4.49 USD | ~\$0.35 USD (Local/Stripe)| ~\$0.30 USD | **\$3.84 USD (~85%)** |

---

## 3. Estrategia Go-To-Market (GTM): Motor Dual B2C + B2B

### A. Bucle Viral B2C en WhatsApp, TikTok y Reels ("El Efecto Reacción")
1. **Gatillo Emocional:** El usuario graba 15 segundos desde su celular y envía el enlace personalizado (`?para=Valentina&de=Carlos&track=TRK-01`) por WhatsApp.
2. **Banner de Dedicatoria Personalizada:** Cuando el destinatario abre el enlace, **SerenatiAr** despliega una tarjeta de bienvenida con su nombre, reproduce la serenata y muestra el botón: **«🎙️ ¿Te gustó? ¡Respóndele con otra serenata o dedícale una a alguien más!»**.
3. **Formatos de Contenido Orgánico (TikTok / Instagram Reels):**
   - *"Intenté cantar desafinado a propósito y mira cómo me dejó la IA de SerenatiAr..."* (Antes vs. Después activando el switch RVC Studio).
   - *"Mi novia pensó que contraté un mariachi/trío real por \$300.000 COP y me costó 1 moneda en SerenatiAr"*.

### B. Canal B2B2C: Alianzas con Floristerías, Desayunos Sorpresa y Chocolaterías
En lugar de competir contra las floristerías, las convertimos en nuestro canal de distribución masiva:
1. **El Producto Aliado ("Tarjeta Sonora QR"):** Desde el nuevo módulo **«🎁 Tarjeta QR Regalos / B2B»** integrado en la aplicación, cualquier floristería o comprador genera en 5 segundos una tarjeta imprimible con código QR y enlace dedicado.
2. **Modelo de Comisión Mayorista:**
   - La floristería compra paquetes **Oro (25 🪙 por \$50.000 COP = \$2.000 COP por moneda)**.
   - Vende el *"Adicional de Serenata con tu Propia Voz en QR"* a sus clientes por **\$15.000 a \$20.000 COP** adicionales al ramo o desayuno sorpresa.
   - **Ganancia para la floristería:** +\$13.000 COP de utilidad pura por ramo sin inventario físico.
   - **Ganancia para SerenatiAr:** Recargas recurrentes de paquetes Oro y adquisición de usuarios con costo de adquisición (CAC) igual a \$0.

---

## 4. Fechas Pico de Activación Comercial (Calendario Anual)
1. **Día de la Madre (Mayo):** Pistas `TRK-01` (*Noche de Balcón*), `TRK-04` (*Sentimiento de Valle*) y `TRK-05` (*Cantina y Despecho*).
2. **Amor y Amistad (Septiembre - Colombia) / San Valentín (14 de Febrero - Global):** Pistas `TRK-02` (*Pop de Arena*), `TRK-03` (*Atardecer en la Cima*) y `TRK-06` (*Coffee Shop Romance*).
3. **Aniversarios, Cumpleaños y Reconciliaciones (365 días del año):** Tráfico constante impulsado por búsquedas rápidas de regalos de último minuto por WhatsApp.
