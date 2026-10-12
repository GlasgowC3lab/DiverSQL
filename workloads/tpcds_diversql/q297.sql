WITH sampled_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),

full_sales_promo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        p.p_promo_name
    FROM sampled_sales ws
    FULL OUTER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
),

site_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        d.d_year
    FROM sampled_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_web_site_sk IN (
        SELECT web_site_sk FROM web_site WHERE web_state = 'CA'
    )
),

promo_agg AS (
    SELECT
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM sampled_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_name
),

set_one AS (
    SELECT
        'Site' AS source,
        CAST(ws.ws_web_site_sk AS VARCHAR) AS key,
        d.d_year AS year,
        ws.ws_net_paid AS amount,
        ws.ws_order_number
    FROM sampled_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_web_site_sk IN (
        SELECT web_site_sk FROM web_site WHERE web_state = 'CA'
    )
),

set_two AS (
    SELECT
        'Promo' AS source,
        agg.p_promo_name AS key,
        NULL AS year,
        agg.total_net_paid AS amount,
        NULL AS order_number
    FROM promo_agg agg
),

union_all_sets AS (
    SELECT source, key, year, amount, ws_order_number FROM set_one
    UNION ALL
    SELECT source, key, year, amount, order_number FROM set_two
),

final_join AS (
    SELECT
        u.source,
        u.key,
        u.year,
        u.amount,
        f.p_promo_name,
        f.ws_net_paid AS promo_ws_net_paid
    FROM union_all_sets u
    FULL OUTER JOIN full_sales_promo f
        ON u.ws_order_number = f.ws_order_number
)
SELECT
    source,
    key,
    year,
    amount,
    p_promo_name,
    promo_ws_net_paid
FROM final_join
ORDER BY source, year DESC NULLS LAST, amount DESC
LIMIT 100
