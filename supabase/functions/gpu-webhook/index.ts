// ============================================================================
// SERENATIAR — FASE 3: SUPABASE EDGE FUNCTION (WEBHOOK RECEPTOR GPU + PASARELAS)
// Ruta: supabase/functions/gpu-webhook/index.ts
// Descripción:
//   Recibe la notificación asíncrona cuando Fal.ai / RunPod termina el renderizado
//   del Audio RVC o del Videoclip Face-Swap (en < 3 minutos).
//   Si el trabajo tuvo éxito: guarda las URLs finales y marca `COMPLETADO` (100%).
//   Si falló la GPU: ejecuta `reembolsar_job_fallido` devolviendo las monedas al usuario.
// ============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

serve(async (req: Request) => {
  try {
    const url = new URL(req.url);
    const serenadeId = url.searchParams.get("serenade_id");
    if (!serenadeId) {
      return new Response(JSON.stringify({ error: "Falta serenade_id" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const payload = await req.json();

    if (payload.status === "OK" || payload.status === "COMPLETED") {
      const audioUrl = payload.payload?.audio_master_url ?? null;
      const videoUrl = payload.payload?.video_faceswap_url ?? null;
      const latencySecs = payload.payload?.inference_time_seconds ?? 95;

      await supabase
        .from("historial_serenatas")
        .update({
          estado_gpu: "COMPLETADO",
          progreso_pct: 100,
          latencia_segundos: latencySecs,
          url_resultado_audio: audioUrl,
          url_resultado_video: videoUrl,
          completed_at: new Date().toISOString(),
        })
        .eq("id_serenata", serenadeId);

      return new Response(JSON.stringify({ ok: true, status: "COMPLETADO" }), { status: 200 });
    } else {
      // Si el nodo GPU falló, reembolsamos automáticamente las monedas al usuario
      await supabase.rpc("reembolsar_job_fallido", { p_id_serenata: serenadeId });
      return new Response(JSON.stringify({ ok: false, status: "ERROR_REEMBOLSADO" }), { status: 200 });
    }
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Webhook error" }),
      { status: 500 }
    );
  }
});
