WITH cs_agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_type,
        cp.cp_department,
        w.w_warehouse_id,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'quarterly'
      AND d.d_year = 1999
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id, cp.cp_type, cp.cp_department,
             w.w_warehouse_id, d.d_year, d.d_month_seq, d.d_date
),
ws_agg AS (
    SELECT
        w.w_warehouse_id,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY w.w_warehouse_id, d.d_year, d.d_month_seq, d.d_date
)
SELECT
    cs.cp_catalog_page_id,
    cs.cp_type,
    cs.w_warehouse_id,
    cs.d_year,
    cs.d_month_seq,
    cs.d_date,
    cs.catalog_net_profit,
    ws.web_net_profit,
    (cs.catalog_net_profit - COALESCE(ws.web_net_profit, 0)) AS profit_diff,
    cs.catalog_quantity,
    ws.web_quantity,
    RANK() OVER (PARTITION BY cs.w_warehouse_id ORDER BY cs.catalog_net_profit DESC) AS catalog_profit_rank,
    SUM(cs.catalog_net_profit) OVER (PARTITION BY cs.w_warehouse_id ORDER BY cs.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_catalog_profit
FROM cs_agg cs
LEFT JOIN ws_agg ws
  ON cs.w_warehouse_id = ws.w_warehouse_id
 AND cs.d_date = ws.d_date
WHERE cs.catalog_net_profit > 0
ORDER BY cs.w_warehouse_id, catalog_profit_rank
LIMIT 100
