-- Model: fat_flt
-- Descrição: Fato de voos contendo métricas operacionais e chaves substitutas das dimensões, derivado da OBT.


{{ config(
    materialized = "table",
    schema       = "dbt_gold",
    tags         = ["gold", "fato", "flights"]
) }}

-- Seleção e preparação dos campos da silver
WITH src AS (
    SELECT
        flight_id,
        flight_date::DATE           AS ful_dat,
        airline_iata_code,
        origin_airport_iata_code,
        dest_airport_iata_code,

        scheduled_departure         AS sch_dep,
        departure_time              AS dep_tme,
        scheduled_arrival           AS sch_arr,
        arrival_time                AS arr_tme,

        distance                    AS dis_val,
        air_time                    AS air_tme,
        elapsed_time                AS elp_tme,
        scheduled_time              AS sch_tme,

        COALESCE(departure_delay, 		0)::DOUBLE PRECISION        AS dep_dly,
        COALESCE(arrival_delay,   		0)::DOUBLE PRECISION        AS arr_dly,
        COALESCE(air_system_delay,		0)::DOUBLE PRECISION        AS sys_dly,
        COALESCE(security_delay,  		0)::DOUBLE PRECISION        AS sec_dly,
        COALESCE(airline_delay,   		0)::DOUBLE PRECISION        AS air_dly,
        COALESCE(late_aircraft_delay,	0)::DOUBLE PRECISION     	AS acf_dly,
        COALESCE(weather_delay,   		0)::DOUBLE PRECISION        AS wea_dly,

        COALESCE(is_overnight_flight, false)                  		AS ovn_flg

    FROM {{ ref('silver_flights') }}
),

-- Junção com a dimensão de companhias aéreas
with_dim_air AS (
    SELECT
        s.*,
        da.srk_air
    FROM src s
    LEFT JOIN {{ ref('dim_air') }} da
        ON s.airline_iata_code = da.air_iat
),

-- Junção com a dimensão de aeroportos (origem e destino)
with_dim_apt AS (
    SELECT
        s.*,
        ao.srk_apt  AS srk_ori,
        ad.srk_apt  AS srk_dst
    FROM with_dim_air s
    LEFT JOIN {{ ref('dim_apt') }} ao
        ON s.origin_airport_iata_code = ao.apt_iat
    LEFT JOIN {{ ref('dim_apt') }} ad
        ON s.dest_airport_iata_code = ad.apt_iat
),

-- Junção com a dimensão de datas
with_dim_dat AS (
    SELECT
        wda.*,
        dd.srk_dat
    FROM with_dim_apt wda
    LEFT JOIN {{ ref('dim_dat') }} dd
        ON wda.ful_dat = dd.ful_dat
),

-- Projeção final dos campos do fato
final AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY flight_id)::BIGINT AS srk_flt,
        srk_dat,
        srk_air,
        srk_ori,
        srk_dst,

        sch_dep,
        dep_tme,
        sch_arr,
        arr_tme,

        dis_val,
        air_tme,
        elp_tme,
        sch_tme,

        dep_dly,
        arr_dly,
        sys_dly,
        sec_dly,
        air_dly,
        acf_dly,
        wea_dly,

        ovn_flg

    FROM with_dim_dat
)

SELECT *
FROM final
