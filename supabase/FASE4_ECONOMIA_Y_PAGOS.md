# FASE 4: ECONOMÍA DE MONEDAS, PASARELAS PPP Y CANDADO FREEMIUM

Este documento detalla la implementación de la **Fase 4** de **SerenatiAr**, conectando la lógica del *Anexo Estratégico 1 (Monetización Global PPP)* con la experiencia interactiva de la Rockola y el backend en Supabase (`https://vlmmuflegeirbcmrsuul.supabase.co`).

---

## 1. Regla Base de Consumo y Modalidad "Audio-First"

El usuario tiene control total sobre qué desea producir y cuántas monedas invertir:

| Modalidad Seleccionada | Costo en Monedas | Pipeline GPU Ejecutado | Entregable Desbloqueado |
| :--- | :---: | :--- | :--- |
| **🎵 Solo Canción (Por defecto)** | **1 Moneda (🪙)** | RVC v2 (`RMVPE`) + Mezcla con Stem Instrumental | Archivo `.WAV / .MP3` Master 320kbps + Link WhatsApp |
| **🎬 + Videoclip IA (Bajo solicitud)** | **3 Monedas (🪙🪙🪙)** | RVC v2 + InsightFace / LivePortrait sobre Plantilla 9:16 | Videoclip Vertical `.MP4` 1080p + Audio Master + Link WhatsApp |

---

## 2. Candado Freemium con Marca de Agua Auditiva (Protección de Costo GPU)

Para maximizar la conversión sin regalar cómputo GPU sin retorno:
1. **Previsualización Gratuita con Marca de Agua Auditiva (`🔒 MODO PREVIEW`):**
   - Al terminar de cantar los 15 segundos, el usuario escucha inmediatamente su serenata procesada en el **Reproductor Master de Estudio**.
   - Si aún no ha invertido monedas en esa pista, el sintetizador Web Audio API superpone cada 3.2 segundos una **marca de agua acústica protectora** (*"🔊 MARCA DE AGUA AUDITIVA ACTIVA — SERENATIAR PREVIEW"*).
2. **Desbloqueo Instantáneo (`🔓 QUITAR MARCA DE AGUA`):**
   - Con un clic en **«Desbloquear Máster Limpio»**, el sistema deduce **1 🪙** (si eligió *Solo Canción*) o **3 🪙** (si eligió *+ Videoclip IA*).
   - La marca de agua desaparece al instante, se genera un archivo `.WAV` real descargable a 44.1kHz y se activa el botón directo **«Enviar Serenata por WhatsApp»**.

---

## 3. Pasarela de Pagos Multi-Región Adaptativa (PPP 4 Tiers)

El modal de Checkout (`#ppp-checkout-modal`) detecta automáticamente el Tier activo y presenta los métodos de pago locales de mayor conversión:

* **🇨🇴 Tier 3 Colombia (`LATAM_COP` — Wompi / ePayco):**
  - Métodos nativos: **📱 Nequi (Notificación Push al celular)**, **🏦 PSE (Débito bancario)**, **🟡 Botón Bancolombia** y **💵 Efecty**.
  - Paquetes: Bronce (\$12.000 COP / 4🪙), Plata (\$25.000 COP / 10🪙), Oro (\$50.000 COP / 25🪙).
* **🇲🇽 Tier 3 México (`LATAM_MXN` — MercadoPago / Stripe MX):**
  - Métodos nativos: **⚡ SPEI Transferencia**, **🏪 OXXO Pay**, **💳 Tarjetas**.
  - Paquetes: Bronce (\$59 MXN / 4🪙), Plata (\$129 MXN / 10🪙), Oro (\$249 MXN / 25🪙).
* **🇺🇸/🇪🇺/🌏 Tiers 1, 2 y 4 (`NA_USD`, `EU_EUR`, `EMERGING_USD` — Stripe Global):**
  - Métodos nativos: **🍎 Apple Pay / Google Pay (1-Click)**, **💳 Tarjeta Internacional**.

---

## 4. Webhook de Pagos en Supabase (`payment-webhook`)

El archivo [`supabase/functions/payment-webhook/index.ts`](./functions/payment-webhook/index.ts) recibe las confirmaciones de **Wompi** (`transaction.updated` con `status === 'APPROVED'`) y **Stripe** (`checkout.session.completed`) e invoca la función transaccional ACID `public.acreditar_recarga_webhook` en PostgreSQL para sumar `monedas_base + bonus` a `billetera_usuarios`.
