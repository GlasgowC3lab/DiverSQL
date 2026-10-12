WITH unified_sales AS (
   SELECT cs.cs_sold_date_sk AS sold_date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_quantity AS quantity,
          cs.cs_sales_price AS price,
          cs.cs_ext_sales_price AS ext_sales,
          cs.cs_net_profit AS profit,
          cs.cs_call_center_sk AS call_center_sk,
          cs.cs_promo_sk AS promo_sk,
          NULL AS store_sk,
          'catalog' AS sales_channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_quantity,
          ss.ss_sales_price,
          ss.ss_ext_sales_price,
          ss.ss_net_profit,
          NULL,
          ss.ss_promo_sk,
          ss.ss_store_sk,
          'store' AS sales_channel
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          ws.ws_quantity,
          ws.ws_sales_price,
          ws.ws_ext_sales_price,
          ws.ws_net_profit,
          NULL,
          ws.ws_promo_sk,
          NULL,
          'web' AS sales_channel
   FROM web_sales ws
),
sales_dim AS (
   SELECT
       us.*,
       d.d_year,
       d.d_month_seq,
       i.i_category,
       i.i_class,
       i.i_brand,
       i.i_color,
       COALESCE(cc.cc_name, s.s_store_name, 'NoLocation') AS location_name,
       CASE WHEN i.i_brand IS NULL THEN 'NoBrand' ELSE i.i_brand END AS brand_coalesced,
       NULLIF(i.i_color, '') AS color_nonempty
   FROM unified_sales us
   LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON us.item_sk = i.i_item_sk
   LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
   LEFT JOIN store s ON us.store_sk = s.s_store_sk
),
enriched_sales AS (
   SELECT
       sd.*,
       CASE
           WHEN EXISTS (
               SELECT 1
               FROM sales_dim sd2
               WHERE sd2.item_sk = sd.item_sk
                 AND sd2.sold_date_sk < sd.sold_date_sk
           ) THEN 1 ELSE 0
       END AS prior_sales_flag,
       (SELECT SUM(sd2.ext_sales)
          FROM sales_dim sd2
         WHERE sd2.item_sk = sd.item_sk
           AND sd2.sold_date_sk < sd.sold_date_sk) AS prior_cum_sales
   FROM sales_dim sd
),
inventory_latest AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          MAX(inv_date_sk) AS latest_date_sk
   FROM inventory
   GROUP BY inv_item_sk, inv_warehouse_sk
),
inventory_detail AS (
   SELECT i.inv_item_sk,
          i.inv_warehouse_sk,
          i.inv_quantity_on_hand,
          d.d_date AS quantity_date
   FROM inventory i
   JOIN inventory_latest il
     ON i.inv_item_sk = il.inv_item_sk
    AND i.inv_warehouse_sk = il.inv_warehouse_sk
    AND i.inv_date_sk = il.latest_date_sk
   LEFT JOIN date_dim d ON il.latest_date_sk = d.d_date_sk
),
agg_sales AS (
   SELECT
       es.d_year,
       es.i_category,
       es.brand_coalesced AS brand,
       es.sales_channel,
       es.location_name,
       SUM(es.ext_sales) AS total_sales,
       SUM(es.profit) AS total_profit,
       COUNT(DISTINCT es.item_sk) AS distinct_items,
       AVG(es.price) AS avg_price,
       MAX(es.price) AS max_price,
       MIN(es.price) AS min_price,
       SUM(es.prior_sales_flag) AS items_with_prior_sales,
       MAX(es.prior_cum_sales) AS max_prior_cum_sales,
       COALESCE(SUM(id.inv_quantity_on_hand), 0) AS total_inventory,
       SUM(CASE WHEN es.ext_sales IS NULL THEN 1 ELSE 0 END) AS null_sales_rows
   FROM enriched_sales es
   LEFT JOIN inventory_detail id ON es.item_sk = id.inv_item_sk
   WHERE (es.d_year BETWEEN 1998 AND 2002 OR es.d_year IS NULL)
     AND es.brand_coalesced IS NOT NULL
     AND (es.ext_sales > 0 OR es.ext_sales IS NULL)
     AND (es.location_name != 'NoLocation' OR es.sales_channel = 'web')
   GROUP BY
       es.d_year,
       es.i_category,
       es.brand_coalesced,
       es.sales_channel,
       es.location_name
   HAVING SUM(es.ext_sales) > 1000
)
SELECT
   a.d_year,
   a.i_category,
   a.brand,
   a.sales_channel,
   a.location_name,
   a.total_sales,
   a.total_profit,
   a.distinct_items,
   a.avg_price,
   a.max_price,
   a.min_price,
   a.items_with_prior_sales,
   a.max_prior_cum_sales,
   a.total_inventory,
   a.null_sales_rows,
   a.total_sales * 0.1 AS ten_percent_sales,
   CONCAT('CAT_', CAST(a.i_category AS varchar), '_', a.sales_channel) AS cat_channel_key,
   ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank_year,
   PERCENT_RANK() OVER (PARTITION BY a.sales_channel ORDER BY a.total_sales) AS sales_pct_rank_channel
FROM agg_sales a
ORDER BY a.total_sales DESC
LIMIT 100
