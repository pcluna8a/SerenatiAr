-- ============================================================================
-- SERENATIAR — ARQUITECTURA DE BASE DE DATOS (SUPABASE POSTGRESQL)
-- ANEXO ESTRATÉGICO 1: MONETIZACIÓN GLOBAL, GEOLOCALIZACIÓN (PPP) Y BILLETERA
-- ============================================================================

-- 1. Extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLA 1: paquetes_recarga (Control Regional de Precios PPP quemados)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.paquetes_recarga (
    id_paquete VARCHAR(32) PRIMARY KEY,
    tier_region VARCHAR(24) NOT NULL,        -- Ej: 'LATAM_COP', 'LATAM_MXN', 'NA_USD', 'EU_EUR', 'EMERGING_USD'
    nombre VARCHAR(32) NOT NULL,             -- 'Bronce', 'Plata', 'Oro'
    moneda_codigo VARCHAR(8) NOT NULL,       -- 'COP', 'MXN', 'USD', 'EUR'
    precio_fijo NUMERIC(12, 2) NOT NULL,     -- Precio cerrado psicológico (ej. 12000, 5.99)
    monedas_base INTEGER NOT NULL CHECK (monedas_base > 0),
    bonus INTEGER NOT NULL DEFAULT 0 CHECK (bonus >= 0),
    pasarela_sugerida VARCHAR(32) NOT NULL,  -- 'WOMPI_EPAYCO', 'MERCADOPAGO', 'STRIPE'
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_paquetes_tier_region ON public.paquetes_recarga(tier_region, activo);

-- Semilla Oficial (Seed Data) con la Matriz Global de Precios PPP
INSERT INTO public.paquetes_recarga (id_paquete, tier_region, nombre, moneda_codigo, precio_fijo, monedas_base, bonus, pasarela_sugerida)
VALUES
    -- TIER 1: Norteamérica y UK (USD / Stripe)
    ('pkg_t1_01', 'NA_USD', 'Bronce', 'USD', 5.99, 4, 0, 'STRIPE'),
    ('pkg_t1_02', 'NA_USD', 'Plata',  'USD', 12.99, 9, 1, 'STRIPE'),
    ('pkg_t1_03', 'NA_USD', 'Oro',    'USD', 24.99, 20, 5, 'STRIPE'),

    -- TIER 2: Europa Occidental (EUR / Stripe)
    ('pkg_t2_01', 'EU_EUR', 'Bronce', 'EUR', 4.99, 4, 0, 'STRIPE'),
    ('pkg_t2_02', 'EU_EUR', 'Plata',  'EUR', 10.99, 9, 1, 'STRIPE'),
    ('pkg_t2_03', 'EU_EUR', 'Oro',    'EUR', 19.99, 20, 5, 'STRIPE'),

    -- TIER 3A: Latinoamérica - Colombia (COP / Wompi - ePayco: Nequi, PSE, Efecty)
    ('pkg_t3_01', 'LATAM_COP', 'Bronce', 'COP', 12000.00, 4, 0, 'WOMPI_EPAYCO'),
    ('pkg_t3_02', 'LATAM_COP', 'Plata',  'COP', 25000.00, 9, 1, 'WOMPI_EPAYCO'),
    ('pkg_t3_03', 'LATAM_COP', 'Oro',    'COP', 50000.00, 20, 5, 'WOMPI_EPAYCO'),

    -- TIER 3B: Latinoamérica - México (MXN / MercadoPago - Stripe)
    ('pkg_t3_mx_01', 'LATAM_MXN', 'Bronce', 'MXN', 59.00, 4, 0, 'MERCADOPAGO'),
    ('pkg_t3_mx_02', 'LATAM_MXN', 'Plata',  'MXN', 129.00, 9, 1, 'MERCADOPAGO'),
    ('pkg_t3_mx_03', 'LATAM_MXN', 'Oro',    'MXN', 249.00, 20, 5, 'MERCADOPAGO'),

    -- TIER 4: Asia y Mercados Emergentes (USD Localizado / Stripe)
    ('pkg_t4_01', 'EMERGING_USD', 'Bronce', 'USD', 1.99, 4, 0, 'STRIPE'),
    ('pkg_t4_02', 'EMERGING_USD', 'Plata',  'USD', 4.49, 9, 1, 'STRIPE'),
    ('pkg_t4_03', 'EMERGING_USD', 'Oro',    'USD', 9.99, 20, 5, 'STRIPE')
ON CONFLICT (id_paquete) DO UPDATE SET
    precio_fijo = EXCLUDED.precio_fijo,
    monedas_base = EXCLUDED.monedas_base,
    bonus = EXCLUDED.bonus,
    pasarela_sugerida = EXCLUDED.pasarela_sugerida;

-- ============================================================================
-- TABLA 2: billetera_usuarios (Integridad Relacional de Monedas)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.billetera_usuarios (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    pais_iso CHAR(2) DEFAULT 'CO',
    tier_region VARCHAR(24) DEFAULT 'LATAM_COP',
    saldo_monedas INTEGER NOT NULL DEFAULT 3 CHECK (saldo_monedas >= 0), -- 3 Monedas Gratis en Onboarding MVP
    muestra_gratis_usada BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TABLA 3: transacciones_monedas (Auditoría de Pagos Webhooks y Consumos GPU)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.transacciones_monedas (
    id_transaccion UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.billetera_usuarios(user_id) ON DELETE CASCADE,
    tipo VARCHAR(24) NOT NULL CHECK (tipo IN ('RECARGA_PAGO', 'BONO_BIENVENIDA', 'CONSUMO_AUDIO', 'CONSUMO_VIDEO')),
    id_paquete VARCHAR(32) REFERENCES public.paquetes_recarga(id_paquete),
    delta_monedas INTEGER NOT NULL, -- Ej: +10 en recarga Plata, -1 en Audio, -3 en Video
    pasarela VARCHAR(32),           -- 'WOMPI', 'EPAYCO', 'STRIPE', 'SYSTEM'
    referencia_externa VARCHAR(128) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TABLA 4: historial_serenatas (Trabajos de Inferencia RVC y Face-Swap)
-- ============================================================================
-- Regla Base de la Economía:
--   AUDIO_RVC = 1 Moneda
--   VIDEO_FACESWAP = 3 Monedas
CREATE TABLE IF NOT EXISTS public.historial_serenatas (
    id_serenata UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.billetera_usuarios(user_id) ON DELETE CASCADE,
    canal_codigo VARCHAR(8) NOT NULL,  -- 'A1' a 'C4'
    formato VARCHAR(24) NOT NULL CHECK (formato IN ('FREEMIUM_WATERMARK', 'AUDIO_RVC', 'VIDEO_FACESWAP')),
    monedas_consumidas INTEGER NOT NULL CHECK (monedas_consumidas IN (0, 1, 3)),
    estado_gpu VARCHAR(24) NOT NULL DEFAULT 'EN_COLA' CHECK (estado_gpu IN ('EN_COLA', 'PROCESANDO', 'COMPLETADO', 'ERROR')),
    url_resultado_media TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- FUNCIÓN TRANSACCIONAL RPC: acreditar_recarga_webhook
-- Suma (monedas_base + bonus) de forma atómica al recibir confirmación de Wompi/Stripe
-- ============================================================================
CREATE OR REPLACE FUNCTION public.acreditar_recarga_webhook(
    p_user_id UUID,
    p_id_paquete VARCHAR(32),
    p_pasarela VARCHAR(32),
    p_referencia_externa VARCHAR(128)
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_monedas_base INTEGER;
    v_bonus INTEGER;
    v_total_acreditar INTEGER;
    v_nuevo_saldo INTEGER;
BEGIN
    SELECT monedas_base, bonus
    INTO v_monedas_base, v_bonus
    FROM public.paquetes_recarga
    WHERE id_paquete = p_id_paquete AND activo = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Paquete % no existe o no está activo', p_id_paquete;
    END IF;

    v_total_acreditar := v_monedas_base + v_bonus;

    INSERT INTO public.transacciones_monedas (user_id, tipo, id_paquete, delta_monedas, pasarela, referencia_externa)
    VALUES (p_user_id, 'RECARGA_PAGO', p_id_paquete, v_total_acreditar, p_pasarela, p_referencia_externa);

    UPDATE public.billetera_usuarios
    SET saldo_monedas = saldo_monedas + v_total_acreditar,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING saldo_monedas INTO v_nuevo_saldo;

    RETURN v_nuevo_saldo;
END;
$$;

-- ============================================================================
-- FUNCIÓN TRANSACCIONAL RPC: descontar_monedas_serenata
-- Aplica la Regla Base: 1 Moneda para Audio RVC, 3 Monedas para Videoclip Face-Swap
-- ============================================================================
CREATE OR REPLACE FUNCTION public.descontar_monedas_serenata(
    p_user_id UUID,
    p_canal_codigo VARCHAR(8),
    p_formato VARCHAR(24) -- 'AUDIO_RVC' (1 moneda) o 'VIDEO_FACESWAP' (3 monedas)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_costo INTEGER;
    v_saldo_actual INTEGER;
    v_id_serenata UUID;
BEGIN
    IF p_formato = 'AUDIO_RVC' THEN
        v_costo := 1;
    ELSIF p_formato = 'VIDEO_FACESWAP' THEN
        v_costo := 3;
    ELSE
        RAISE EXCEPTION 'Formato inválido: %', p_formato;
    END IF;

    SELECT saldo_monedas INTO v_saldo_actual
    FROM public.billetera_usuarios
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_saldo_actual < v_costo THEN
        RAISE EXCEPTION 'Saldo insuficiente de monedas. Tienes % y necesitas %', v_saldo_actual, v_costo;
    END IF;

    UPDATE public.billetera_usuarios
    SET saldo_monedas = saldo_monedas - v_costo,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    INSERT INTO public.transacciones_monedas (user_id, tipo, delta_monedas, pasarela)
    VALUES (
        p_user_id,
        CASE WHEN p_formato = 'AUDIO_RVC' THEN 'CONSUMO_AUDIO' ELSE 'CONSUMO_VIDEO' END,
        -v_costo,
        'SYSTEM'
    );

    INSERT INTO public.historial_serenatas (user_id, canal_codigo, formato, monedas_consumidas, estado_gpu)
    VALUES (p_user_id, p_canal_codigo, p_formato, v_costo, 'EN_COLA')
    RETURNING id_serenata INTO v_id_serenata;

    RETURN v_id_serenata;
END;
$$;
