// ============================================================================
// SERENATIAR - FASE 4: SUPABASE EDGE FUNCTION `payment-webhook`
// Recibe Webhooks de Wompi (Colombia: Nequi, PSE, Bancolombia, Efecty) y
// Stripe (Global: Apple Pay, Google Pay, Tarjetas) y acredita las monedas
// atómicamente mediante la función ACID `public.acreditar_recarga_webhook`.
// ============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-event-checksum, stripe-signature",
};

interface NormalizedPaymentEvent {
  provider: "WOMPI" | "STRIPE";
  status: "APPROVED" | "DECLINED" | "ERROR";
  userId: string;
  packageId: string;
  reference: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    const rawBody = await req.text();
    const payload = JSON.parse(rawBody);

    let eventData: NormalizedPaymentEvent | null = null;

    // 1. Detectar si el Webhook proviene de WOMPI (Colombia - Tier 3 LATAM_COP)
    if (payload.event === "transaction.updated" && payload.data?.transaction) {
      const tx = payload.data.transaction;
      // En Wompi, enviamos userId e id_paquete codificados en reference o customer_data:
      // Formato esperado de reference: "SR|<user_uuid>|<id_paquete>|<timestamp>"
      const parts = String(tx.reference || "").split("|");
      const userId = parts[1] || tx.customer_data?.legal_id || "";
      const packageId = parts[2] || "pkg_t3_02";

      eventData = {
        provider: "WOMPI",
        status: tx.status === "APPROVED" ? "APPROVED" : "DECLINED",
        userId,
        packageId,
        reference: `WOMPI-${tx.id}-${tx.payment_method_type || "LOCAL"}`,
      };
    }
    // 2. Detectar si el Webhook proviene de STRIPE (Tiers 1, 2 y 4)
    else if (payload.type === "checkout.session.completed" && payload.data?.object) {
      const session = payload.data.object;
      eventData = {
        provider: "STRIPE",
        status: session.payment_status === "paid" ? "APPROVED" : "DECLINED",
        userId: session.metadata?.user_id || "",
        packageId: session.metadata?.id_paquete || "pkg_t1_02",
        reference: `STRIPE-${session.id}`,
      };
    }

    if (!eventData || !eventData.userId) {
      return new Response(
        JSON.stringify({ error: "Payload de pasarela no reconocido o sin user_id." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Solo acreditamos monedas cuando el pago está 100% APROBADO
    if (eventData.status !== "APPROVED") {
      return new Response(
        JSON.stringify({
          received: true,
          accredited: false,
          reason: `Transacción en estado ${eventData.status}`,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Ejecutar transacción ACID en PostgreSQL (`acreditar_recarga_webhook`)
    const { data: rpcResult, error: rpcError } = await supabaseAdmin.rpc(
      "acreditar_recarga_webhook",
      {
        p_user_id: eventData.userId,
        p_id_paquete: eventData.packageId,
        p_pasarela_ref: eventData.reference,
      }
    );

    if (rpcError) {
      return new Response(
        JSON.stringify({ error: rpcError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        received: true,
        accredited: true,
        provider: eventData.provider,
        wallet: rpcResult,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Error interno en payment-webhook" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
