-- -------------------------------------------------------------------------------------------------
--
--                                        SCRIPT DE CONSULTAS (SELECTS)                                                
-- 
-- Data Criação ...........: 01/12/2025
-- Autor(es) ..............: Matheus Henrique Dos Santos
-- Banco de Dados .........: PostgreSQL 16
-- Banco de Dados(nome) ...: dw
-- 
-- Últimas alterações:
--
-- -------------------------------------------------------------------------------------------------
SET search_path TO gold;


-- Consulta 1: KPI’s do sistema aéreo (Cards)
SELECT
    COUNT(f.srk_flt) AS total_voos,
    AVG(CASE WHEN f.arr_dly <= 0 THEN 1 ELSE 0 END) * 100 AS otp_pct,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY f.arr_dly) AS mediana_atraso,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY f.arr_dly) AS p95_atraso,
    AVG(CASE WHEN f.arr_dly > 30 THEN 1 ELSE 0 END) * 100 AS pct_atrasos_severos,
    SUM(f.arr_dly) AS impacto_total_sistema
FROM gold.fat_flt AS f;

-- Consulta 2: Performance Geral das Companhias Aéreas (Scatter Plot)
SELECT
    a.air_name,
    COUNT(*) AS total_voos,
    AVG(f.arr_dly) AS media_atraso,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY f.arr_dly) AS p95,
    AVG(CASE WHEN f.arr_dly > 30 THEN 1 ELSE 0 END) * 100 AS pct_atrasos_severos,
    AVG(CASE WHEN f.arr_dly <= 0 THEN 1 ELSE 0 END) * 100 AS otp_pct
FROM gold.fat_flt AS f
JOIN gold.dim_air AS a ON f.srk_air = a.srk_air
GROUP BY a.air_name
ORDER BY media_atraso DESC;

-- Consulta 3: Performance Geral dos Aeroportos (Scatter Plot)
SELECT
    ap.apt_name,
    ap.cty_name,
    ap.st_name,
    COUNT(*) AS total_voos,
    AVG(f.arr_dly) AS media_atraso,
    AVG(f.dep_dly) AS media_atraso_partida,
    SUM(f.arr_dly) AS impacto_total_atraso
FROM gold.fat_flt AS f
JOIN gold.dim_apt AS ap ON f.srk_ori = ap.srk_apt
GROUP BY ap.apt_name, ap.cty_name, ap.st_name
ORDER BY impacto_total_atraso DESC;

-- Consulta 4: Atraso por Dia da Semana (Barra Vertical)
SELECT
    d.dow AS dia_semana,
    COUNT(*) AS total_voos,
    AVG(f.arr_dly) AS media_atraso,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY f.arr_dly) AS p95
FROM gold.fat_flt AS f
JOIN gold.dim_dat AS d ON f.srk_dat = d.srk_dat
GROUP BY d.dow
ORDER BY d.dow;

-- Consulta 5: Atraso por Mês (Line Chart)
SELECT
    d.mm AS mes,
    COUNT(*) AS total_voos,
    AVG(f.arr_dly) AS media_atraso,
    SUM(f.arr_dly) AS impacto_total
FROM gold.fat_flt AS f
JOIN gold.dim_dat AS d ON f.srk_dat = d.srk_dat
GROUP BY d.mm
ORDER BY d.mm;

-- Consulta 6: Impacto dos Atrasos por Motivo (Barra Horizontal Ordenada "Cima-Baixo")
SELECT motivo, total_atraso
FROM (
    SELECT 'Sistema Aéreo'      AS motivo, SUM(f.sys_dly)  AS total_atraso FROM gold.fat_flt AS f
    UNION ALL
    SELECT 'Segurança'          AS motivo, SUM(f.sec_dly)  AS total_atraso FROM gold.fat_flt AS f
    UNION ALL
    SELECT 'Companhia'          AS motivo, SUM(f.air_dly)  AS total_atraso FROM gold.fat_flt AS f
    UNION ALL
    SELECT 'Aeronave Anterior'  AS motivo, SUM(f.acft_dly) AS total_atraso FROM gold.fat_flt AS f
    UNION ALL
    SELECT 'Clima'              AS motivo, SUM(f.wx_dly)   AS total_atraso FROM gold.fat_flt AS f
) t
ORDER BY total_atraso DESC;

-- Consulta 7: Top 10 Piores Rotas (Barra Horizontal)
SELECT 
    ori.apt_iata AS origem,
    dst.apt_iata AS destino,
    COUNT(*) AS total_voos,
    AVG(f.arr_dly) AS media_atraso,
    SUM(f.arr_dly) AS impacto_total
FROM gold.fat_flt AS f
JOIN gold.dim_apt AS ori ON f.srk_ori = ori.srk_apt
JOIN gold.dim_apt AS dst ON f.srk_dst = dst.srk_apt
GROUP BY ori.apt_iata, dst.apt_iata
HAVING COUNT(*) >= 50
ORDER BY impacto_total DESC
LIMIT 10;

-- Consulta 8: Impacto dos Atrasos por Período do Dia (Barra Horizontal)
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM f.sch_dep) BETWEEN 0 AND 5  THEN 'Madrugada'
        WHEN EXTRACT(HOUR FROM f.sch_dep) BETWEEN 6 AND 11 THEN 'Manhã'
        WHEN EXTRACT(HOUR FROM f.sch_dep) BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noite'
    END AS periodo,
    COUNT(*) AS total_voos,
    AVG(f.dep_dly) AS atraso_partida,
    AVG(f.arr_dly) AS atraso_chegada,
    SUM(f.arr_dly) AS impacto_total
FROM gold.fat_flt AS f
GROUP BY periodo
ORDER BY impacto_total DESC;

-- Consulta 9: Atraso Médio por Duração do Voo (Colunas Verticais - 3 categorias)
SELECT 
    CASE 
        WHEN f.elp_time <= 90 THEN 'Curta'
        WHEN f.elp_time <= 240 THEN 'Média'
        ELSE 'Longa'
    END AS categoria,
    COUNT(*) AS total_voos,
    AVG(f.arr_dly) AS media_atraso,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY f.arr_dly) AS p95
FROM gold.fat_flt AS f
WHERE f.elp_time IS NOT NULL
GROUP BY categoria
ORDER BY media_atraso DESC;

-- Consulta 10: Taxa de Recuperação de Atraso (Barra Segmentada Horizontal)
WITH resumo AS (
    SELECT
        SUM(CASE 
                WHEN dep_dly > 0 AND arr_dly <= 0 THEN 1 
                ELSE 0 
            END) AS recuperou_totalmente,

        SUM(CASE 
                WHEN dep_dly > 0 AND arr_dly < dep_dly THEN 1 
                ELSE 0 
            END) AS recuperou_parcialmente,

        SUM(CASE 
                WHEN dep_dly > 0 AND arr_dly >= dep_dly THEN 1
                ELSE 0
            END) AS nao_recuperou,

        SUM(CASE 
                WHEN dep_dly <= 0 THEN 1 
                ELSE 0 
            END) AS sem_atraso
    FROM gold.fat_flt
)

SELECT
    recuperou_totalmente,
    recuperou_parcialmente,
    nao_recuperou,
    sem_atraso,
    (recuperou_totalmente 
        + recuperou_parcialmente
        + nao_recuperou
        + sem_atraso) AS total_voos,

    ROUND(recuperou_totalmente::numeric / 
          (recuperou_totalmente + recuperou_parcialmente + nao_recuperou + sem_atraso) * 100, 2)
          AS pct_recuperou_totalmente,
    ROUND(recuperou_parcialmente::numeric / 
          (recuperou_totalmente + recuperou_parcialmente + nao_recuperou + sem_atraso) * 100, 2)
          AS pct_recuperou_parcialmente,
    ROUND(nao_recuperou::numeric / 
          (recuperou_totalmente + recuperou_parcialmente + nao_recuperou + sem_atraso) * 100, 2)
          AS pct_nao_recuperou,
    ROUND(sem_atraso::numeric / 
          (recuperou_totalmente + recuperou_parcialmente + nao_recuperou + sem_atraso) * 100, 2)
          AS pct_sem_atraso
FROM resumo;
