WITH
    small_dim AS (
        SELECT sm_ship_mode_id
        FROM ship_mode
        WHERE sm_type = 'AIR'
        LIMIT 5
    ),
    agg AS (
        SELECT
            sm.sm_ship_mode_id,
            d.d_year AS year,
            'web'    AS channel,
            SUM(ws.ws_net_paid) AS total_net_paid
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE d.d_year = 2001
        GROUP BY sm.sm_ship_mode_id, d.d_year

        UNION ALL

        SELECT
            sm.sm_ship_mode_id,
            d.d_year AS year,
            'catalog' AS channel,
            SUM(cs.cs_net_paid) AS total_net_paid
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE d.d_year = 2001
        GROUP BY sm.sm_ship_mode_id, d.d_year
    ),
    ranked AS (
        SELECT
            sd.sm_ship_mode_id AS small_ship_mode,
            a.channel,
            a.year,
            a.total_net_paid,
            ROW_NUMBER() OVER (PARTITION BY sd.sm_ship_mode_id ORDER BY a.total_net_paid DESC) AS rn
        FROM small_dim sd
        CROSS JOIN agg a
        WHERE a.sm_ship_mode_id = sd.sm_ship_mode_id
    )
SELECT
    small_ship_mode,
    channel,
    year,
    total_net_paid
FROM ranked
WHERE rn <= 5
ORDER BY small_ship_mode, rn
LIMIT 100
