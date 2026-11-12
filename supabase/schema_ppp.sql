-- ============================================================================
-- SERENATIAR — FASE 3: ARQUITECTURA BACKEND COMPLETA (SUPABASE POSTGRESQL)
-- Incluye:
--   1. Catálogo Georreferenciado (catalogo_pistas_geo)
--   2. Paquetes Regionales PPP (paquetes_recarga)
--   3. Billeteras de Monedas con integridad ACID (billetera_usuarios)
--   4. Captura de Leads Puerta Falsa / Onboarding (mvp_leads)
--   5. Cola de Inferencia Serverless GPU (historial_serenatas + webhooks)
--   6. Políticas RLS (Row Level Security) + Storage Buckets
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. TABLA: mvp_leads (Puerta Falsa + Onboarding de 3 Monedas Gratis)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.mvp_leads (
    id_lead UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    pista_seleccionada VARCHAR(128) NOT NULL,
    destinatario VARCHAR(64) NOT NULL,
    formato_preferido VARCHAR(64) NOT NULL,
    pais_iso CHAR(2) DEFAULT 'CO',
    tier_region VARCHAR(24) DEFAULT 'LATAM_COP',
    ticket_reserva VARCHAR(24) NOT NULL,
    monedas_otorgadas INTEGER NOT NULL DEFAULT 3,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mvp_leads_email ON public.mvp_leads(email);

-- Permitir inserción anónima desde el Frontend (Puerta Falsa con anon_key)
ALTER TABLE public.mvp_leads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir registro publico de leads MVP" ON public.mvp_leads;
CREATE POLICY "Permitir registro publico de leads MVP"
    ON public.mvp_leads
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- ============================================================================
-- 2. TABLA: paquetes_recarga (Matriz Global de Precios PPP quemados)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.paquetes_recarga (
    id_paquete VARCHAR(32) PRIMARY KEY,
    tier_region VARCHAR(24) NOT NULL,
    nombre VARCHAR(32) NOT NULL,
    moneda_codigo VARCHAR(8) NOT NULL,
    precio_fijo NUMERIC(12, 2) NOT NULL,
    monedas_base INTEGER NOT NULL CHECK (monedas_base > 0),
    bonus INTEGER NOT NULL DEFAULT 0 CHECK (bonus >= 0),
    pasarela_sugerida VARCHAR(32) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_paquetes_tier_region ON public.paquetes_recarga(tier_region, activo);

ALTER TABLE public.paquetes_recarga ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura publica de paquetes PPP" ON public.paquetes_recarga;
CREATE POLICY "Lectura publica de paquetes PPP"
    ON public.paquetes_recarga
    FOR SELECT
    TO anon, authenticated
    USING (activo = true);

INSERT INTO public.paquetes_recarga (id_paquete, tier_region, nombre, moneda_codigo, precio_fijo, monedas_base, bonus, pasarela_sugerida)
VALUES
    ('pkg_t1_01', 'NA_USD',       'Bronce', 'USD', 5.99,     4,  0, 'STRIPE'),
    ('pkg_t1_02', 'NA_USD',       'Plata',  'USD', 12.99,    9,  1, 'STRIPE'),
    ('pkg_t1_03', 'NA_USD',       'Oro',    'USD', 24.99,    20, 5, 'STRIPE'),
    ('pkg_t2_01', 'EU_EUR',       'Bronce', 'EUR', 4.99,     4,  0, 'STRIPE'),
    ('pkg_t2_02', 'EU_EUR',       'Plata',  'EUR', 10.99,    9,  1, 'STRIPE'),
    ('pkg_t2_03', 'EU_EUR',       'Oro',    'EUR', 19.99,    20, 5, 'STRIPE'),
    ('pkg_t3_01', 'LATAM_COP',    'Bronce', 'COP', 12000.00, 4,  0, 'WOMPI_EPAYCO'),
    ('pkg_t3_02', 'LATAM_COP',    'Plata',  'COP', 25000.00, 9,  1, 'WOMPI_EPAYCO'),
    ('pkg_t3_03', 'LATAM_COP',    'Oro',    'COP', 50000.00, 20, 5, 'WOMPI_EPAYCO'),
    ('pkg_t3_mx_01', 'LATAM_MXN', 'Bronce', 'MXN', 59.00,    4,  0, 'MERCADOPAGO'),
    ('pkg_t3_mx_02', 'LATAM_MXN', 'Plata',  'MXN', 129.00,   9,  1, 'MERCADOPAGO'),
    ('pkg_t3_mx_03', 'LATAM_MXN', 'Oro',    'MXN', 249.00,   20, 5, 'MERCADOPAGO'),
    ('pkg_t4_01', 'EMERGING_USD', 'Bronce', 'USD', 1.99,     4,  0, 'STRIPE'),
    ('pkg_t4_02', 'EMERGING_USD', 'Plata',  'USD', 4.49,     9,  1, 'STRIPE'),
    ('pkg_t4_03', 'EMERGING_USD', 'Oro',    'USD', 9.99,     20, 5, 'STRIPE')
ON CONFLICT (id_paquete) DO UPDATE SET
    precio_fijo = EXCLUDED.precio_fijo,
    monedas_base = EXCLUDED.monedas_base,
    bonus = EXCLUDED.bonus,
    pasarela_sugerida = EXCLUDED.pasarela_sugerida;

-- ============================================================================
-- 3. TABLA: catalogo_pistas_geo (Catálogo Global de Type-Beats por Continente)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.catalogo_pistas_geo (
    id_pista VARCHAR(16) PRIMARY KEY,
    codigo_rockola VARCHAR(8) NOT NULL,
    geo_zone VARCHAR(16) NOT NULL,
    categoria_local VARCHAR(64) NOT NULL,
    titulo VARCHAR(64) NOT NULL,
    instrumentacion TEXT NOT NULL,
    vibra_referencia VARCHAR(128) NOT NULL,
    bpm INTEGER NOT NULL,
    tonalidad VARCHAR(16) NOT NULL,
    stem_instrumental_url TEXT NOT NULL,
    stem_vocal_guide_url TEXT NOT NULL,
    plantilla_video_id VARCHAR(32) NOT NULL,
    plantilla_video_url TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_catalogo_geo_zone ON public.catalogo_pistas_geo(geo_zone, activo);

ALTER TABLE public.catalogo_pistas_geo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura publica de catalogo georreferenciado" ON public.catalogo_pistas_geo;
CREATE POLICY "Lectura publica de catalogo georreferenciado"
    ON public.catalogo_pistas_geo
    FOR SELECT
    TO anon, authenticated
    USING (activo = true);

INSERT INTO public.catalogo_pistas_geo (
    id_pista, codigo_rockola, geo_zone, categoria_local, titulo, instrumentacion, vibra_referencia, bpm, tonalidad,
    stem_instrumental_url, stem_vocal_guide_url, plantilla_video_id, plantilla_video_url
)
VALUES
    ('TRK-01', 'P01', 'LATAM', 'Acústico y Pop',     'Noche de Balcón',      'Guitarras acústicas, tiple y requinto',       'Los Panchos / Julio Jaramillo', 76,  'A Minor', 'stems/TRK-01_inst.wav', 'stems/TRK-01_guide.wav', 'TPL-01-BALCON',     'templates/TPL-01-BALCON.mp4'),
    ('TRK-02', 'P02', 'LATAM', 'Acústico y Pop',     'Pop de Arena',         'Piano eléctrico cálido y batería suave',      'Chayanne / Luis Miguel 90s',    78,  'C Major', 'stems/TRK-02_inst.wav', 'stems/TRK-02_guide.wav', 'TPL-02-ARENA',      'templates/TPL-02-ARENA.mp4'),
    ('TRK-03', 'P03', 'LATAM', 'Urbano Suave',       'Atardecer en la Cima', 'Beat reggaetón muy suave con guitarra',       'Feid acústico / Camilo',        86,  'F Minor', 'stems/TRK-03_inst.wav', 'stems/TRK-03_guide.wav', 'TPL-03-CIMA',       'templates/TPL-03-CIMA.mp4'),
    ('TRK-04', 'P04', 'LATAM', 'De nuestra tierra',  'Sentimiento de Valle', 'Acordeón romántico lento y caja suave',       'Vallenato Romántico',           84,  'D Major', 'stems/TRK-04_inst.wav', 'stems/TRK-04_guide.wav', 'TPL-04-VALLE',      'templates/TPL-04-VALLE.mp4'),
    ('TRK-05', 'P05', 'LATAM', 'De nuestra tierra',  'Cantina y Despecho',   'Trompetas suaves, requinto y guitarrón',      'Ranchera / Música Popular',     88,  'G Major', 'stems/TRK-05_inst.wav', 'stems/TRK-05_guide.wav', 'TPL-05-CANTINA',    'templates/TPL-05-CANTINA.mp4'),
    ('TRK-06', 'P06', 'NA_UK', 'Acoustic Pop',       'Coffee Shop Romance',  'Solo guitarra acústica cálida fingerpicking', 'Ed Sheeran / Shawn Mendes',     92,  'G Major', 'stems/TRK-06_inst.wav', 'stems/TRK-06_guide.wav', 'TPL-06-COFFEESHOP', 'templates/TPL-06-COFFEESHOP.mp4'),
    ('TRK-07', 'P07', 'NA_UK', 'R&B / Soul',         'Midnight Piano',       'Piano de cola con reverberación profunda',    'John Legend / Adele',           68,  'Eb Major','stems/TRK-07_inst.wav', 'stems/TRK-07_guide.wav', 'TPL-07-MIDNIGHT',   'templates/TPL-07-MIDNIGHT.mp4'),
    ('TRK-08', 'P08', 'NA_UK', 'Country Romántico',  'Nashville Sunset',     'Guitarra con slide y percusión rústica',      'Taylor Swift / Morgan Wallen',  96,  'D Major', 'stems/TRK-08_inst.wav', 'stems/TRK-08_guide.wav', 'TPL-08-NASHVILLE',  'templates/TPL-08-NASHVILLE.mp4'),
    ('TRK-09', 'P09', 'EUROPE','Indie Folk',         'Nordic Woods',         'Guitarras rápidas, bombo y coros etéreos',    'Mumford & Sons / Hozier',       114, 'C Major', 'stems/TRK-09_inst.wav', 'stems/TRK-09_guide.wav', 'TPL-09-NORDIC',     'templates/TPL-09-NORDIC.mp4'),
    ('TRK-10', 'P10', 'EUROPE','Euro-Pop Sintético', 'Neon Heartbeat',       'Sintetizadores retro 80s con bajo marcado',   'The Weeknd / Dua Lipa',         118, 'A Minor', 'stems/TRK-10_inst.wav', 'stems/TRK-10_guide.wav', 'TPL-10-NEON',       'templates/TPL-10-NEON.mp4'),
    ('TRK-11', 'P11', 'ASIA',  'K-Drama OST',        'Cherry Blossom Tears', 'Cuerdas orquestales y piano dramático',       'OST Doramas Coreanos (Seúl)',   70,  'F Major', 'stems/TRK-11_inst.wav', 'stems/TRK-11_guide.wav', 'TPL-11-KDRAMA',     'templates/TPL-11-KDRAMA.mp4'),
    ('TRK-12', 'P12', 'ASIA',  'J-Pop / Anime Lento','Tokyo Starlight',      'Batería pop con arreglos de cuerdas ligeras', 'Anime Ballad (Tokio)',          98,  'E Major', 'stems/TRK-12_inst.wav', 'stems/TRK-12_guide.wav', 'TPL-12-TOKYO',      'templates/TPL-12-TOKYO.mp4')
ON CONFLICT (id_pista) DO NOTHING;

-- ============================================================================
-- 4. TABLA: billetera_usuarios (Saldos de Monedas con Integridad Relacional)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.billetera_usuarios (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    pais_iso CHAR(2) DEFAULT 'CO',
    tier_region VARCHAR(24) DEFAULT 'LATAM_COP',
    saldo_monedas INTEGER NOT NULL DEFAULT 3 CHECK (saldo_monedas >= 0),
    muestra_gratis_usada BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 5. TABLA: transacciones_monedas (Libro Mayor / Ledger Inmutable)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.transacciones_monedas (
    id_transaccion UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.billetera_usuarios(user_id) ON DELETE CASCADE,
    tipo VARCHAR(24) NOT NULL CHECK (tipo IN ('RECARGA_PAGO', 'BONO_BIENVENIDA', 'CONSUMO_AUDIO', 'CONSUMO_VIDEO', 'REEMBOLSO_ERROR_GPU')),
    id_paquete VARCHAR(32) REFERENCES public.paquetes_recarga(id_paquete),
    delta_monedas INTEGER NOT NULL,
    pasarela VARCHAR(32),
    referencia_externa VARCHAR(128) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 6. TABLA: historial_serenatas (Orquestación de Jobs RVC y Face-Swap en GPU)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.historial_serenatas (
    id_serenata UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.billetera_usuarios(user_id) ON DELETE CASCADE,
    id_pista VARCHAR(16) NOT NULL REFERENCES public.catalogo_pistas_geo(id_pista),
    formato VARCHAR(24) NOT NULL CHECK (formato IN ('FREEMIUM_WATERMARK', 'AUDIO_RVC', 'VIDEO_FACESWAP')),
    monedas_consumidas INTEGER NOT NULL CHECK (monedas_consumidas IN (0, 1, 3)),
    -- Inputs temporales en Supabase Storage (auto-eliminados a las 24h por privacidad biométrica)
    input_voz_storage_path TEXT NOT NULL,
    input_selfies_paths JSONB DEFAULT '[]'::jsonb,
    -- Estado del pipeline Serverless GPU (Fal.ai / RunPod / Replicate)
    proveedor_gpu VARCHAR(24) DEFAULT 'FAL_AI',
    gpu_job_id VARCHAR(128),
    estado_gpu VARCHAR(32) NOT NULL DEFAULT 'EN_COLA'
        CHECK (estado_gpu IN ('EN_COLA', 'PROCESANDO_RVC', 'MEZCLANDO_STEMS', 'PROCESANDO_FACESWAP', 'COMPLETADO', 'ERROR_REEMBOLSADO')),
    progreso_pct INTEGER NOT NULL DEFAULT 0 CHECK (progreso_pct BETWEEN 0 AND 100),
    latencia_segundos INTEGER,
    url_resultado_audio TEXT,
    url_resultado_video TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_serenatas_user_estado ON public.historial_serenatas(user_id, estado_gpu);

-- ============================================================================
-- 7. FUNCIONES RPC TRANSACCIONALES (ACID)
-- ============================================================================

-- 7.1 Acreditar Recarga tras Webhook de Wompi / ePayco / Stripe
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

-- 7.2 Crear Trabajo de Serenata y Descontar Monedas (1🪙 Audio / 3🪙 Video)
CREATE OR REPLACE FUNCTION public.iniciar_job_serenata(
    p_user_id UUID,
    p_id_pista VARCHAR(16),
    p_formato VARCHAR(24),
    p_input_voz_path TEXT,
    p_input_selfies JSONB DEFAULT '[]'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_costo INTEGER;
    v_saldo_actual INTEGER;
    v_muestra_usada BOOLEAN;
    v_id_serenata UUID;
BEGIN
    SELECT saldo_monedas, muestra_gratis_usada
    INTO v_saldo_actual, v_muestra_usada
    FROM public.billetera_usuarios
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario % no encontrado en billetera_usuarios', p_user_id;
    END IF;

    IF p_formato = 'FREEMIUM_WATERMARK' THEN
        IF v_muestra_usada THEN
            RAISE EXCEPTION 'La muestra gratis ya fue utilizada en esta cuenta';
        END IF;
        v_costo := 0;
        UPDATE public.billetera_usuarios SET muestra_gratis_usada = TRUE, updated_at = NOW() WHERE user_id = p_user_id;
    ELSIF p_formato = 'AUDIO_RVC' THEN
        v_costo := 1;
    ELSIF p_formato = 'VIDEO_FACESWAP' THEN
        v_costo := 3;
    ELSE
        RAISE EXCEPTION 'Formato inválido: %', p_formato;
    END IF;

    IF v_costo > 0 THEN
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
            'SYSTEM_GPU'
        );
    END IF;

    INSERT INTO public.historial_serenatas (
        user_id, id_pista, formato, monedas_consumidas, input_voz_storage_path, input_selfies_paths, estado_gpu, progreso_pct
    )
    VALUES (
        p_user_id, p_id_pista, p_formato, v_costo, p_input_voz_path, p_input_selfies, 'EN_COLA', 5
    )
    RETURNING id_serenata INTO v_id_serenata;

    RETURN v_id_serenata;
END;
$$;

-- 7.3 Reembolso Automático si falla la GPU Serverless (Garantía al Usuario)
CREATE OR REPLACE FUNCTION public.reembolsar_job_fallido(
    p_id_serenata UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_monedas INTEGER;
    v_estado VARCHAR(32);
BEGIN
    SELECT user_id, monedas_consumidas, estado_gpu
    INTO v_user_id, v_monedas, v_estado
    FROM public.historial_serenatas
    WHERE id_serenata = p_id_serenata
    FOR UPDATE;

    IF v_estado = 'ERROR_REEMBOLSADO' OR v_estado = 'COMPLETADO' THEN
        RETURN;
    END IF;

    UPDATE public.historial_serenatas
    SET estado_gpu = 'ERROR_REEMBOLSADO',
        progreso_pct = 0
    WHERE id_serenata = p_id_serenata;

    IF v_monedas > 0 THEN
        UPDATE public.billetera_usuarios
        SET saldo_monedas = saldo_monedas + v_monedas,
            updated_at = NOW()
        WHERE user_id = v_user_id;

        INSERT INTO public.transacciones_monedas (user_id, tipo, delta_monedas, pasarela, referencia_externa)
        VALUES (v_user_id, 'REEMBOLSO_ERROR_GPU', v_monedas, 'SYSTEM_ROLLBACK', p_id_serenata::text);
    END IF;
END;
$$;
