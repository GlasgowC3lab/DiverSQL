WITH store_agg AS (
    SELECT d.d_year AS d_year,
           s.s_state AS state,
           'store' AS sales_channel,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, s.s_state
),
web_agg AS (
    SELECT d.d_year AS d_year,
           w.w_state AS state,
           'web' AS sales_channel,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY d.d_year, w.w_state
),
catalog_agg AS (
    SELECT d.d_year AS d_year,
           cc.cc_state AS state,
           'catalog' AS sales_channel,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, cc.cc_state
)
SELECT *
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM catalog_agg
) AS all_sales
ORDER BY d_year, state, sales_channel
