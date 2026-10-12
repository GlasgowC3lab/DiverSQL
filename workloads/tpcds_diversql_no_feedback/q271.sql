WITH sales_by_mode AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_code,
        sm.sm_carrier,
        CONCAT(sm.sm_carrier, '-', sm.sm_code) AS carrier_mode,
        regexp_extract(sm.sm_carrier, '([A-Z]{3})', 1) AS carrier_prefix,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost
    FROM tpcds.catalog_sales cs
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE (
            sm.sm_carrier LIKE '%AIR%'
            OR regexp_like(sm.sm_carrier, '.*R$')
          )
      AND sm.sm_code IS NOT NULL
    GROUP BY
        sm.sm_ship_mode_sk,
        sm.sm_code,
        sm.sm_carrier,
        CONCAT(sm.sm_carrier, '-', sm.sm_code),
        regexp_extract(sm.sm_carrier, '([A-Z]{3})', 1)
    HAVING
        SUM(cs.cs_net_paid_inc_ship_tax) > 5000
        AND COUNT(*) >= 10
)
SELECT
    sm_ship_mode_sk,
    sm_code,
    sm_carrier,
    carrier_mode,
    carrier_prefix,
    total_net_paid,
    order_cnt,
    avg_ship_cost,
    ROW_NUMBER() OVER (PARTITION BY sm_carrier ORDER BY total_net_paid DESC) AS carrier_rank
FROM sales_by_mode
ORDER BY total_net_paid DESC
LIMIT 100
