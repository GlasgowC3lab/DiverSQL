WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_fy_week_seq AS week_seq,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS amount,
        'sales' AS activity_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_fy_week_seq BETWEEN 5 AND 10
      AND d.d_year = 2002
    GROUP BY d.d_year, d.d_fy_week_seq, cs.cs_item_sk
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_fy_week_seq AS week_seq,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amount) AS amount,
        'returns' AS activity_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_fy_week_seq BETWEEN 5 AND 10
      AND d.d_year = 2002
    GROUP BY d.d_year, d.d_fy_week_seq, cr.cr_item_sk
)
SELECT year, week_seq, item_sk, amount, activity_type
FROM sales_agg
UNION
SELECT year, week_seq, item_sk, amount, activity_type
FROM returns_agg
ORDER BY year, week_seq, item_sk, activity_type
LIMIT 100
