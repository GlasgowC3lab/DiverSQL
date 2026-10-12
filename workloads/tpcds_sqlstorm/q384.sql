WITH cs AS (
   SELECT
      cs.cs_call_center_sk AS call_center_sk,
      CAST(NULL AS INTEGER) AS store_sk,
      CAST(NULL AS INTEGER) AS web_page_sk,
      cc.cc_call_center_id AS entity_id,
      cs.cs_item_sk AS item_sk,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid_inc_tax AS net_paid,
      cs.cs_net_profit AS net_profit,
      concat(CAST(d.d_year AS VARCHAR), '-', lpad(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
      'catalog' AS source
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
), ss AS (
   SELECT
      CAST(NULL AS INTEGER) AS call_center_sk,
      ss.ss_store_sk AS store_sk,
      CAST(NULL AS INTEGER) AS web_page_sk,
      s.s_store_id AS entity_id,
      ss.ss_item_sk AS item_sk,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid_inc_tax AS net_paid,
      ss.ss_net_profit AS net_profit,
      concat(CAST(d.d_year AS VARCHAR), '-', lpad(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
      'store' AS source
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
), ws AS (
   SELECT
      CAST(NULL AS INTEGER) AS call_center_sk,
      CAST(NULL AS INTEGER) AS store_sk,
      ws.ws_web_page_sk AS web_page_sk,
      wp.wp_web_page_id AS entity_id,
      ws.ws_item_sk AS item_sk,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid_inc_tax AS net_paid,
      ws.ws_net_profit AS net_profit,
      concat(CAST(d.d_year AS VARCHAR), '-', lpad(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
      'web' AS source
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
), all_sales AS (
   SELECT * FROM cs
   UNION ALL
   SELECT * FROM ss
   UNION ALL
   SELECT * FROM ws
), agg AS (
   SELECT
      entity_id,
      source,
      year_month,
      SUM(net_profit) AS total_net_profit,
      SUM(net_paid) AS total_net_paid,
      SUM(quantity) AS total_quantity,
      MAX(call_center_sk) AS call_center_sk,
      MAX(store_sk) AS store_sk,
      MAX(web_page_sk) AS web_page_sk
   FROM all_sales
   GROUP BY entity_id, source, year_month
)
SELECT
   agg.entity_id,
   COALESCE(cc.cc_name, s.s_store_name, wp.wp_url, 'UNKNOWN') AS entity_name,
   agg.source,
   agg.year_month,
   agg.total_net_profit,
   agg.total_net_paid,
   CASE WHEN agg.total_net_paid = 0 THEN NULL ELSE agg.total_net_profit / agg.total_net_paid END AS profit_margin,
   ROW_NUMBER() OVER (PARTITION BY agg.source ORDER BY agg.total_net_profit DESC) AS profit_rank,
   MAX(agg.total_net_profit) OVER (PARTITION BY agg.source) AS max_monthly_profit,
   SUM(agg.total_net_profit) OVER (PARTITION BY agg.source ORDER BY agg.year_month ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
   CASE WHEN agg.total_net_profit > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_flag,
   (SELECT i.i_item_id || ':' || CAST(SUM(a2.quantity) AS VARCHAR)
      FROM all_sales a2
      JOIN item i ON a2.item_sk = i.i_item_sk
      WHERE a2.entity_id = agg.entity_id
        AND a2.source = agg.source
        AND a2.year_month = agg.year_month
      GROUP BY i.i_item_id
      ORDER BY SUM(a2.quantity) DESC
      LIMIT 1) AS top_product,
   CASE WHEN agg.source = 'catalog' THEN
        COALESCE(
            (SELECT SUM(cr.cr_return_quantity)
             FROM catalog_returns cr
             JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
             WHERE dr.d_year = CAST(split_part(agg.year_month, '-', 1) AS INTEGER)
               AND dr.d_moy = CAST(split_part(agg.year_month, '-', 2) AS INTEGER)
               AND cr.cr_call_center_sk = agg.call_center_sk), 0)
        / NULLIF(agg.total_quantity, 0)
    ELSE NULL END AS return_rate
FROM agg
LEFT JOIN call_center cc ON agg.call_center_sk = cc.cc_call_center_sk
LEFT JOIN store s ON agg.store_sk = s.s_store_sk
LEFT JOIN web_page wp ON agg.web_page_sk = wp.wp_web_page_sk
ORDER BY agg.entity_id, agg.year_month
