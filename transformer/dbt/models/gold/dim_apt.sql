-- Model: dim_apt
-- Descrição: Dimensão de aeroportos derivada da tabela OBT.


{{ config(
    materialized = "table",
    schema       = "dbt_gold",
    tags         = ["gold", "dim", "airport"]
) }}

-- Consolidação dos aeroportos de origem e destino a partir da silver_flights.
WITH airports_raw AS (

    SELECT DISTINCT
        origin_airport_iata_code AS apt_iat,
        origin_airport_name      AS apt_nam,
        origin_city              AS cty_nam,
        origin_state             AS ste_cod,
        origin_latitude          AS lat_val,
        origin_longitude         AS lon_val
    FROM {{ ref('silver_flights') }}
    WHERE origin_airport_iata_code IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT
        dest_airport_iata_code   AS apt_iat,
        dest_airport_name        AS apt_nam,
        dest_city                AS cty_nam,
        dest_state               AS ste_cod,
        dest_latitude            AS lat_val,
        dest_longitude           AS lon_val
    FROM {{ ref('silver_flights') }}
    WHERE dest_airport_iata_code IS NOT NULL

),

-- Projeção e organização das colunas finais da dimensão.
clean AS (
    SELECT
        apt_iat,
        apt_nam,
        ste_cod,
        coalesce({{ state_name_expr('ste_cod') }}, 'Unknown')::varchar(100) as ste_nam,
        cty_nam,
        lat_val,
        lon_val
    FROM airports_raw
)

-- Criação da chave substituta e ordenação da dimensão.
SELECT
    ROW_NUMBER() OVER (ORDER BY apt_iat)::BIGINT AS srk_apt,
    apt_iat,
    apt_nam,
    ste_cod,
    ste_nam,
    cty_nam,
    lat_val,
    lon_val
FROM clean
ORDER BY apt_iat
