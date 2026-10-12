WITH base AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        w.web_site_id,
        p.p_promo_name,
        sm.sm_type,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        p.p_channel_email,
        p.p_channel_tv,
        w.web_manager,
        w.web_rec_end_date
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE p.p_channel_email = 'Y'
      AND p.p_channel_tv = 'N'
      AND w.web_manager = 'Jimmy Pope'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND w.web_rec_end_date > DATE '2000-01-01'
      AND c.c_preferred_cust_flag = 'Y'
),

agg1 AS (
    SELECT
        web_site_id,
        p_promo_name,
        sm_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_qty
    FROM base
    GROUP BY GROUPING SETS (
        (web_site_id, p_promo_name, sm_type),
        (web_site_id, p_promo_name),
        (web_site_id),
        (p_promo_name)
    )
),

excluded AS (
    SELECT
        web_site_id,
        p_promo_name,
        sm_type,
        total_sales,
        total_profit,
        total_qty
    FROM agg1
    WHERE total_profit < 0
),

combined AS (
    SELECT
        web_site_id,
        p_promo_name,
        sm_type,
        total_sales,
        total_profit,
        total_qty
    FROM agg1
    EXCEPT
    SELECT
        web_site_id,
        p_promo_name,
        sm_type,
        total_sales,
        total_profit,
        total_qty
    FROM excluded
),

ranked AS (
    SELECT
        web_site_id,
        p_promo_name,
        sm_type,
        total_sales,
        total_profit,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_profit DESC) AS rnk
    FROM combined
)
SELECT
    web_site_id,
    p_promo_name,
    sm_type,
    total_sales,
    total_profit,
    total_qty
FROM ranked
WHERE rnk <= 3
ORDER BY web_site_id, total_profit DESC
LIMIT 100
