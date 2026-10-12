WITH warehouse_profit AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_gmt_offset,
        COUNT(DISTINCT site.web_site_sk) AS distinct_web_sites,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state, w.w_gmt_offset
)
SELECT
    wp.w_warehouse_sk,
    wp.w_warehouse_name,
    wp.w_city,
    wp.w_state,
    wp.distinct_web_sites,
    wp.catalog_net_profit,
    wp.web_net_profit,
    wp.total_net_profit,
    CASE
        WHEN wp.total_net_profit >= 100000 THEN 'High'
        WHEN wp.total_net_profit >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY wp.total_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY wp.w_gmt_offset) AS gmt_offset_dense_rank
FROM warehouse_profit wp
ORDER BY profit_rank
