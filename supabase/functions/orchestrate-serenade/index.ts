// ============================================================================
// SERENATIAR — FASE 3: SUPABASE EDGE FUNCTION (ORQUESTADOR GPU SERVERLESS)
// Ruta: supabase/functions/orchestrate-serenade/index.ts
// Descripción:
//   1. Valida el saldo de monedas del usuario en PostgreSQL vía `iniciar_job_serenata`.
//   2. Obtiene los stems (`instrumental` + `vocal_guide`) y `plantilla_video` de `catalogo_pistas_geo`.
//   3. Dispara en paralelo o secuencia los motores Serverless GPU (Fal.ai / Replicate / RunPod):
//      - Paso A: RVC v2 Voice-to-Voice (timbre del usuario sobre el vocal_guide) + mezcla con Type-Beat.
//      - Paso B (Si formato == 'VIDEO_FACESWAP'): InsightFace + LivePortrait sobre la Plantilla Maestra 9:16.
//   4. Registra el `gpu_job_id` y expone un webhook para actualizar `historial_serenatas` en tiempo real.
// ============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SerenadeJobPayload {
  userId: string;
  trackId: string; // 'TRK-01' a 'TRK-12'
  format: "FREEMIUM_WATERMARK" | "AUDIO_RVC" | "VIDEO_FACESWAP";
  voiceAudioStoragePath: string;
  selfieStoragePaths?: string[]; // 3 selfies para el Character Sheet
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const falApiKey = Deno.env.get("FAL_KEY")!; // API Key de Fal.ai Serverless GPU

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const body: SerenadeJobPayload = await req.json();

    // 1. Validar que para VIDEO_FACESWAP existan las 3 selfies del Character Sheet
    if (body.format === "VIDEO_FACESWAP" && (!body.selfieStoragePaths || body.selfieStoragePaths.length < 1)) {
      return new Response(
        JSON.stringify({ error: "Se requiere al menos 1 selfie (recomendado 3) para el videoclip Face-Swap." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Ejecutar transacción atómica en PostgreSQL: descontar monedas (0, 1 o 3) y crear registro en cola
    const { data: serenadeId, error: rpcError } = await supabase.rpc("iniciar_job_serenata", {
      p_user_id: body.userId,
      p_id_pista: body.trackId,
      p_formato: body.format,
      p_input_voz_path: body.voiceAudioStoragePath,
      p_input_selfies: body.selfieStoragePaths ?? [],
    });

    if (rpcError) {
      return new Response(
        JSON.stringify({ error: rpcError.message }),
        { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Consultar los assets maestros de la pista seleccionada (Type-Beat + Plantilla 9:16)
    const { data: trackAsset, error: trackError } = await supabase
      .from("catalogo_pistas_geo")
      .select("*")
      .eq("id_pista", body.trackId)
      .single();

    if (trackError || !trackAsset) {
      await supabase.rpc("reembolsar_job_fallido", { p_id_serenata: serenadeId });
      throw new Error("No se encontró la pista en catalogo_pistas_geo");
    }

    // 4. Generar URLs firmadas temporales (15 min) para que el cluster GPU descargue la voz y las selfies
    const { data: signedVoice } = await supabase.storage
      .from("user-biometrics-temp")
      .createSignedUrl(body.voiceAudioStoragePath, 900);

    // 5. Llamar al motor Serverless GPU (Fal.ai Queue API con Webhook de retorno)
    const webhookUrl = `${supabaseUrl}/functions/v1/gpu-webhook?serenade_id=${serenadeId}`;

    const falEndpoint =
      body.format === "VIDEO_FACESWAP"
        ? "https://queue.fal.run/fal-ai/rvc-and-faceswap-pipeline"
        : "https://queue.fal.run/fal-ai/rvc-voice-conversion";

    const gpuResponse = await fetch(`${falEndpoint}?fal_webhook=${encodeURIComponent(webhookUrl)}`, {
      method: "POST",
      headers: {
        Authorization: `Key ${falApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        serenade_id: serenadeId,
        user_voice_sample_url: signedVoice?.signedUrl,
        guide_vocal_stem_url: trackAsset.stem_vocal_guide_url,
        instrumental_stem_url: trackAsset.stem_instrumental_url,
        apply_audio_watermark: body.format === "FREEMIUM_WATERMARK",
        pitch_shift_semitones: 0,
        f0_method: "rmvpe", // Mejor algoritmo de extracción de pitch para canto
        index_rate: 0.75,
        video_template_url: body.format === "VIDEO_FACESWAP" ? trackAsset.plantilla_video_url : null,
        user_selfies_urls: body.selfieStoragePaths ?? [],
        face_restore_weight: 0.5, // CodeFormer/GFPGAN balanceado para mantener identidad
      }),
    });

    const gpuQueueData = await gpuResponse.json();

    // 6. Actualizar estado del Job a PROCESANDO_RVC
    await supabase
      .from("historial_serenatas")
      .update({
        gpu_job_id: gpuQueueData.request_id ?? `job_${Date.now()}`,
        estado_gpu: "PROCESANDO_RVC",
        progreso_pct: 25,
      })
      .eq("id_serenata", serenadeId);

    return new Response(
      JSON.stringify({
        ok: true,
        serenadeId,
        gpuJobId: gpuQueueData.request_id,
        status: "PROCESANDO_RVC",
        estimatedSeconds: body.format === "VIDEO_FACESWAP" ? 135 : 45,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Error interno en orquestador GPU" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
