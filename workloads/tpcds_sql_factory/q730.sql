WITH promo_agg AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS channel,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_net_profit,
        w.w_state AS state,
        w.w_country AS country
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cs.cs_promo_sk, w.w_state, w.w_country
    UNION ALL
    SELECT
        ws.ws_promo_sk AS promo_sk,
        'web' AS channel,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        w.w_state AS state,
        site.web_country AS country
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    GROUP BY ws.ws_promo_sk, w.w_state, site.web_country
)
SELECT
    promo_sk,
    channel,
    state,
    country,
    total_discount,
    total_net_profit,
    CASE
        WHEN total_discount = 0 THEN 'No Discount'
        WHEN total_discount / NULLIF(total_net_profit, 0) > 2 THEN 'Aggressive'
        WHEN total_discount / NULLIF(total_net_profit, 0) > 1 THEN 'Moderate'
        ELSE 'Mild'
    END AS discount_intensity,
    RANK() OVER (ORDER BY total_discount DESC) AS discount_rank,
    DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS profit_dense_rank,
    SUM(total_net_profit) OVER (
        ORDER BY total_discount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_profit_by_discount
FROM promo_agg
WHERE total_discount IS NOT NULL
ORDER BY discount_rank
LIMIT 100
