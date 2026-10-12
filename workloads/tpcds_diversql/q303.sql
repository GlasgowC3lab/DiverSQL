WITH
    -- Aggregate store sales by promotion and time (pre‑aggregation CTE)
    store_sales_agg AS (
        SELECT
            ss_promo_sk,
            ss_sold_time_sk,
            SUM(ss_net_paid) AS total_store_net_paid,
            COUNT(*)       AS store_txn_cnt
        FROM store_sales
        WHERE ss_ext_sales_price > 1000
        GROUP BY ss_promo_sk, ss_sold_time_sk
    ),
    -- Intersect promotions that use both email and TV channels (INTERSECT)
    intersected_promos AS (
        SELECT p_promo_sk FROM promotion WHERE p_channel_email = 'Y'
        INTERSECT
        SELECT p_promo_sk FROM promotion WHERE p_channel_tv = 'Y'
    ),
    -- Second alias of promotion for a different role
    promo_alias AS (
        SELECT p_promo_sk, p_promo_name, p_discount_active FROM promotion
    )
SELECT
    p.p_promo_id,
    p.p_promo_name,
    td.t_meal_time,
    wh.w_warehouse_name,
    agg.total_store_net_paid,
    agg.store_txn_cnt,
    (
        SELECT SUM(ws3.ws_net_paid)
        FROM web_sales ws3
        WHERE ws3.ws_promo_sk = p.p_promo_sk
    ) AS web_net_paid_for_promo,
    ws.ws_net_profit
FROM intersected_promos ip
    -- join to the main promotion table
    JOIN promotion p ON ip.p_promo_sk = p.p_promo_sk
    -- bring in the aggregated store‑sales data
    JOIN store_sales_agg agg ON agg.ss_promo_sk = p.p_promo_sk
    -- link the time dimension for the store‑sales aggregation
    JOIN time_dim td ON agg.ss_sold_time_sk = td.t_time_sk
    -- full outer join to web_sales (uses the allowed join rule but keeps unmatched rows)
    FULL OUTER JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    -- join to web_page and web_site via their foreign keys
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    -- join to warehouse (full outer join already used ws, now a regular inner join for the same key)
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    -- second alias of promotion for a different analytical perspective
    JOIN promo_alias p2 ON ws.ws_promo_sk = p2.p_promo_sk
    -- second alias of time_dim for the web_sales sold time
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
WHERE p.p_promo_sk NOT IN (
        SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'N'
    )
    AND td.t_meal_time = 'dinner'
ORDER BY agg.total_store_net_paid DESC, p.p_promo_id
LIMIT 100
