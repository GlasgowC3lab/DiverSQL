WITH store_sales_agg AS (
   SELECT 
      s.s_store_sk,
      s.s_store_name,
      d.d_year,
      d.d_month_seq,
      SUM(ss.ss_net_profit) AS store_net_profit,
      SUM(ss.ss_ext_sales_price) AS store_ext_sales,
      COUNT(*) AS store_sales_cnt,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rn_profit
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
   SELECT 
      cp.cp_catalog_page_sk,
      cp.cp_department,
      d.d_year,
      d.d_month_seq,
      SUM(cs.cs_net_profit) AS catalog_net_profit,
      SUM(cs.cs_ext_sales_price) AS catalog_ext_sales,
      COUNT(*) AS catalog_sales_cnt,
      ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rn_profit
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cp.cp_catalog_page_sk, cp.cp_department, d.d_year, d.d_month_seq
),
web_sales_agg AS (
   SELECT 
      ws.ws_web_page_sk,
      wp.wp_type,
      d.d_year,
      d.d_month_seq,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_ext_sales_price) AS web_ext_sales,
      COUNT(*) AS web_sales_cnt,
      ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn_profit
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_web_page_sk, wp.wp_type, d.d_year, d.d_month_seq
),
item_promo AS (
   SELECT 
      i.i_item_sk,
      i.i_product_name,
      COALESCE(p.p_promo_name, 'NO_PROMO') AS promo_name,
      CASE WHEN p.p_discount_active = 'Y' THEN 'Y' ELSE 'N' END AS discount_active_flag
   FROM item i
   LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
),
top_items_union AS (
   SELECT 'store' AS channel, ss.ss_item_sk AS item_sk, ss.ss_net_profit AS net_profit,
          d.d_year, d.d_month_seq,
          ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_net_profit DESC) AS rn
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION ALL
   SELECT 'catalog' AS channel, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit,
          d.d_year, d.d_month_seq,
          ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS rn
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION ALL
   SELECT 'web' AS channel, ws.ws_item_sk AS item_sk, ws.ws_net_profit AS net_profit,
          d.d_year, d.d_month_seq,
          ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)

SELECT
   COALESCE(s.s_store_name, 'ALL') AS store_name,
   COALESCE(cp.cp_department, 'ALL') AS catalog_department,
   COALESCE(wp.wp_type, 'ALL') AS web_page_type,
   d.d_date,
   d.d_year,
   d.d_month_seq,
   CASE
      WHEN s.s_store_sk IS NOT NULL THEN 'Store Channel'
      WHEN cp.cp_catalog_page_sk IS NOT NULL THEN 'Catalog Channel'
      WHEN wp.wp_web_page_sk IS NOT NULL THEN 'Web Channel'
      ELSE 'Mixed'
   END AS channel_desc,
   CONCAT('Prof:', CAST(COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS VARCHAR)) AS total_profit_str,
   COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_profit,
   RANK() OVER (ORDER BY COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) DESC) AS overall_profit_rank,
   (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_sold_date_sk = d.d_date_sk) AS store_sales_on_date,
   CASE WHEN EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_returned_date_sk = d.d_date_sk) THEN 'RETURNED' ELSE 'NO_RETURN' END AS return_flag,
   (SELECT COUNT(*) FROM top_items_union t
        WHERE t.channel = CASE 
               WHEN s.s_store_sk IS NOT NULL THEN 'store'
               WHEN cp.cp_catalog_page_sk IS NOT NULL THEN 'catalog'
               ELSE 'web'
             END
          AND t.rn <= 3
          AND t.d_year = d.d_year
          AND t.d_month_seq = d.d_month_seq) AS top3_items_count,
   SUBSTRING(COALESCE(s.s_store_name, ''), 1, 3) AS store_name_prefix,
   (SELECT discount_active_flag FROM item_promo ip LIMIT 1) AS any_discount_flag,
   CASE
      WHEN ss.store_net_profit IS NULL AND cs.catalog_net_profit IS NULL AND ws.web_net_profit IS NULL THEN NULL
      WHEN ss.store_net_profit IS NULL THEN -1
      WHEN cs.catalog_net_profit IS NULL THEN -2
      WHEN ws.web_net_profit IS NULL THEN -3
      ELSE 0
   END AS profit_null_indicator,
   date_diff('day', d.d_date, date_trunc('year', d.d_date) + INTERVAL '1' YEAR - INTERVAL '1' DAY) AS days_until_year_end
FROM date_dim d
LEFT JOIN store_sales_agg ss ON d.d_year = ss.d_year AND d.d_month_seq = ss.d_month_seq
LEFT JOIN catalog_sales_agg cs ON d.d_year = cs.d_year AND d.d_month_seq = cs.d_month_seq
LEFT JOIN web_sales_agg ws ON d.d_year = ws.d_year AND d.d_month_seq = ws.d_month_seq
LEFT JOIN store s ON ss.s_store_sk = s.s_store_sk
LEFT JOIN catalog_page cp ON cs.cp_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND (ss.rn_profit = 1 OR cs.rn_profit = 1 OR ws.rn_profit = 1)
ORDER BY total_profit DESC
LIMIT 100
