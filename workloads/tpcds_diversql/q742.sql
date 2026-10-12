WITH
    high_value_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_ext_sales_price,
            cs.cs_sold_date_sk,
            cs.cs_ship_mode_sk
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_ext_sales_price > 1500
    ),
    intersect_orders AS (
        SELECT cs.cs_order_number
        FROM tpcds.catalog_sales cs
        JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE sm.sm_code = 'AIR'
        INTERSECT
        SELECT cs.cs_order_number
        FROM tpcds.catalog_sales cs
        JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE p.p_discount_active = 'Y'
    )

SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    d.d_year,
    d.d_month_seq,
    sm_l.sm_ship_mode_id,
    sm_l.sm_type,
    (SELECT MIN(d2.d_year) FROM tpcds.date_dim d2) AS min_year
FROM intersect_orders io
JOIN tpcds.catalog_sales cs ON io.cs_order_number = cs.cs_order_number
JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT sm.sm_ship_mode_id, sm.sm_type
    FROM tpcds.ship_mode sm
    WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
) sm_l
WHERE cs.cs_ext_sales_price > 500

UNION ALL

SELECT
    hv.cs_order_number,
    hv.cs_ext_sales_price,
    d2.d_year,
    d2.d_month_seq,
    CAST(NULL AS varchar) AS sm_ship_mode_id,
    CAST(NULL AS varchar) AS sm_type,
    (SELECT MIN(d3.d_year) FROM tpcds.date_dim d3) AS min_year
FROM high_value_sales hv
JOIN tpcds.date_dim d2 ON hv.cs_sold_date_sk = d2.d_date_sk
WHERE hv.cs_ext_sales_price > 2000

ORDER BY cs_ext_sales_price DESC
OFFSET 0 LIMIT 100
