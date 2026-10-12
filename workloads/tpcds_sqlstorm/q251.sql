WITH unified_sales AS (
   SELECT
     cs.cs_sold_date_sk AS date_sk,
     d.d_date,
     'catalog' AS channel,
     cs.cs_warehouse_sk AS location_sk,
     w.w_state AS region,
     cs.cs_item_sk AS item_sk,
     i.i_category,
     i.i_class,
     cs.cs_promo_sk AS promo_sk,
     p.p_promo_name AS promo_name,
     cs.cs_quantity AS quantity,
     cs.cs_ext_sales_price AS ext_sales_price,
     cs.cs_ext_tax AS ext_tax,
     cs.cs_net_paid AS net_paid,
     cs.cs_net_profit AS net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk

   UNION ALL

   SELECT
     ss.ss_sold_date_sk AS date_sk,
     d.d_date,
     'store' AS channel,
     ss.ss_store_sk AS location_sk,
     s.s_state AS region,
     ss.ss_item_sk AS item_sk,
     i.i_category,
     i.i_class,
     ss.ss_promo_sk AS promo_sk,
     p.p_promo_name AS promo_name,
     ss.ss_quantity AS quantity,
     ss.ss_ext_sales_price AS ext_sales_price,
     ss.ss_ext_tax AS ext_tax,
     ss.ss_net_paid AS net_paid,
     ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk

   UNION ALL

   SELECT
     ws.ws_sold_date_sk AS date_sk,
     d.d_date,
     'web' AS channel,
     ws.ws_warehouse_sk AS location_sk,
     w.w_state AS region,
     ws.ws_item_sk AS item_sk,
     i.i_category,
     i.i_class,
     ws.ws_promo_sk AS promo_sk,
     p.p_promo_name AS promo_name,
     ws.ws_quantity AS quantity,
     ws.ws_ext_sales_price AS ext_sales_price,
     ws.ws_ext_tax AS ext_tax,
     ws.ws_net_paid AS net_paid,
     ws.ws_net_profit AS net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
aggregated AS (
  SELECT
    date_sk,
    d_date,
    channel,
    COALESCE(region, 'UNKNOWN') AS region,
    i_category,
    i_class,
    COALESCE(promo_name, 'No Promo') AS promo_name,
    SUM(quantity) AS total_quantity,
    SUM(ext_sales_price) AS total_sales,
    SUM(ext_tax) AS total_tax,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    approx_percentile(net_profit, 0.5) FILTER (WHERE net_profit IS NOT NULL) AS median_profit_per_sale
  FROM unified_sales
  GROUP BY ROLLUP (date_sk, d_date, channel, region, i_category, i_class, promo_name)
  HAVING SUM(ext_sales_price) > 0
)
SELECT
  date_sk,
  d_date,
  channel,
  region,
  i_category,
  i_class,
  promo_name,
  total_quantity,
  total_sales,
  total_tax,
  total_net_paid,
  total_net_profit,
  median_profit_per_sale,
  RANK() OVER (PARTITION BY date_sk, channel ORDER BY total_net_profit DESC) AS profit_rank,
  SUM(total_net_profit) OVER (PARTITION BY date_sk ORDER BY channel ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_date
FROM aggregated
ORDER BY date_sk, channel, profit_rank
LIMIT 200
