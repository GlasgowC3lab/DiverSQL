WITH store_monthly AS (
    SELECT s.s_store_name AS store_name,
           d.d_year,
           d.d_month_seq,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_net_paid) AS store_net_paid,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
),
catalog_monthly AS (
    SELECT cp.cp_catalog_page_id AS catalog_page,
           d.d_year,
           d.d_month_seq,
           SUM(cs.cs_net_profit) AS catalog_net_profit,
           SUM(cs.cs_net_paid) AS catalog_net_paid,
           COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT w.web_name AS web_site,
           d.d_year,
           d.d_month_seq,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_net_paid) AS web_net_paid,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY w.web_name, d.d_year, d.d_month_seq
),
store_monthly_with_prev AS (
    SELECT cur.*,
           prev.store_net_profit AS prev_store_net_profit,
           prev.store_net_paid AS prev_store_net_paid,
           CASE WHEN prev.store_net_profit IS NOT NULL AND prev.store_net_profit <> 0
                THEN (cur.store_net_profit - prev.store_net_profit) / prev.store_net_profit
                ELSE NULL END AS yoy_store_profit_change,
           CASE WHEN prev.store_net_paid IS NOT NULL AND prev.store_net_paid <> 0
                THEN (cur.store_net_paid - prev.store_net_paid) / prev.store_net_paid
                ELSE NULL END AS yoy_store_paid_change
    FROM store_monthly cur
    LEFT JOIN store_monthly prev
      ON cur.store_name = prev.store_name
     AND cur.d_month_seq = prev.d_month_seq + 12
)
SELECT sm.store_name,
       sm.d_year,
       sm.d_month_seq,
       sm.store_net_profit,
       sm.store_net_paid,
       sm.store_txn_cnt,
       COALESCE(cm.catalog_net_profit, 0) AS catalog_net_profit,
       COALESCE(cm.catalog_net_paid, 0) AS catalog_net_paid,
       COALESCE(cm.catalog_txn_cnt, 0) AS catalog_txn_cnt,
       COALESCE(wm.web_net_profit, 0) AS web_net_profit,
       COALESCE(wm.web_net_paid, 0) AS web_net_paid,
       COALESCE(wm.web_txn_cnt, 0) AS web_txn_cnt,
       ROUND((sm.store_net_profit + COALESCE(cm.catalog_net_profit,0) + COALESCE(wm.web_net_profit,0)) / NULLIF(sm.store_net_profit,0), 4) AS profit_ratio_vs_store,
       sm.prev_store_net_profit,
       sm.yoy_store_profit_change,
       ROW_NUMBER() OVER (PARTITION BY sm.d_year, sm.d_month_seq ORDER BY sm.store_net_profit DESC) AS store_rank_month
FROM store_monthly_with_prev sm
LEFT JOIN catalog_monthly cm
  ON sm.d_year = cm.d_year AND sm.d_month_seq = cm.d_month_seq
LEFT JOIN web_monthly wm
  ON sm.d_year = wm.d_year AND sm.d_month_seq = wm.d_month_seq
WHERE sm.store_net_profit > 0
ORDER BY sm.store_net_profit DESC
LIMIT 100
