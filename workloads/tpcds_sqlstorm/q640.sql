WITH
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        s.s_store_id AS entity_id,
        s.s_store_name AS entity_name,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_sold_date_sk, s.s_store_id, s.s_store_name
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        w.web_site_id AS entity_id,
        w.web_name AS entity_name,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_sold_date_sk, w.web_site_id, w.web_name
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cp.cp_catalog_page_id AS entity_id,
        cp.cp_department AS entity_name,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_sold_date_sk, cp.cp_catalog_page_id, cp.cp_department
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
),
promo_stats AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM promotion p
),
final_with_ranking AS (
    SELECT
        cs.date_sk,
        cs.channel,
        cs.entity_id,
        cs.entity_name,
        cs.profit,
        cs.quantity,
        cs.orders,
        COALESCE(cs.profit, 0) AS profit_coalesce,
        cs.profit / NULLIF(cs.orders, 0) AS profit_per_order,
        CASE
            WHEN cs.profit > 100000 THEN 'HIGH'
            WHEN cs.profit > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_class,
        CONCAT(cs.entity_id, '-', CAST(cs.date_sk AS VARCHAR)) AS composite_key,
        LOWER(cs.channel) AS channel_lower,
        RANK() OVER (PARTITION BY cs.channel ORDER BY cs.profit DESC) AS profit_rank,
        AVG(cs.profit) OVER (PARTITION BY cs.channel ORDER BY cs.date_sk ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS moving_avg_4d,
        (SELECT AVG(cs2.profit) FROM combined_sales cs2 WHERE cs2.channel = cs.channel) AS overall_avg_profit,
        (SELECT MAX(cs3.profit) FROM combined_sales cs3 WHERE cs3.date_sk = cs.date_sk) AS max_profit_same_date,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name
    FROM combined_sales cs
    LEFT JOIN promo_stats p
        ON cs.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE cs.profit IS NOT NULL
)
SELECT
    date_sk,
    channel,
    entity_id,
    entity_name,
    profit,
    quantity,
    orders,
    profit_coalesce,
    profit_per_order,
    profit_class,
    composite_key,
    channel_lower,
    profit_rank,
    moving_avg_4d,
    overall_avg_profit,
    max_profit_same_date,
    promo_name
FROM final_with_ranking
WHERE profit_rank <= 10
ORDER BY channel, profit_rank
