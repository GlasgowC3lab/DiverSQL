WITH date_info AS (
 SELECT d_date_sk, d_date, d_year, d_month_seq, d_day_name
 FROM date_dim
),
item_info AS (
 SELECT i_item_sk, i_product_name, i_brand, i_category, i_class, i_manufact
 FROM item
),
channel_sales AS (
 SELECT cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS channel_sk,
        'catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount_amt
 FROM catalog_sales cs
 UNION ALL
 SELECT ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        'store',
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt
 FROM store_sales ss
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        'web',
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
 FROM web_sales ws
),
promo_agg AS (
 SELECT p.p_item_sk AS item_sk,
        p.p_start_date_sk AS start_sk,
        p.p_end_date_sk AS end_sk,
        SUM(p.p_cost) AS total_promo_cost
 FROM promotion p
 GROUP BY p.p_item_sk, p.p_start_date_sk, p.p_end_date_sk
),
sales_agg AS (
 SELECT
   cs.date_sk,
   cs.item_sk,
   cs.channel,
   cs.channel_sk,
   SUM(cs.quantity) AS total_qty,
   SUM(cs.net_paid) AS total_sales,
   SUM(cs.profit) AS total_profit,
   AVG(CASE WHEN cs.quantity <> 0 THEN cs.discount_amt / cs.quantity END) AS avg_discount,
   APPROX_DISTINCT(cs.channel_sk) AS distinct_channels,
   (SELECT COALESCE(SUM(p.total_promo_cost),0)
    FROM promo_agg p
    WHERE (cs.item_sk IS NOT NULL AND p.item_sk = cs.item_sk)
      AND cs.date_sk BETWEEN p.start_sk AND p.end_sk) AS promo_cost_total
 FROM channel_sales cs
 GROUP BY GROUPING SETS (
   (cs.date_sk, cs.item_sk, cs.channel, cs.channel_sk),
   (cs.date_sk, cs.channel, cs.channel_sk),
   (cs.date_sk)
 )
),
ranked_sales AS (
 SELECT
   d.d_date AS sale_date,
   d.d_year AS year,
   d.d_month_seq AS month,
   d.d_day_name AS day_name,
   i.i_product_name AS product_name,
   COALESCE(a.channel, 'ALL') AS channel,
   COALESCE(cc.cc_name, st.s_store_name, ws_site.web_name) AS channel_entity_name,
   a.total_qty,
   a.total_sales,
   a.total_profit,
   a.avg_discount,
   a.promo_cost_total,
   a.distinct_channels,
   ROW_NUMBER() OVER (PARTITION BY a.date_sk ORDER BY a.total_sales DESC) AS sales_rank
 FROM sales_agg a
 LEFT JOIN date_info d ON a.date_sk = d.d_date_sk
 LEFT JOIN item_info i ON a.item_sk = i.i_item_sk
 LEFT JOIN call_center cc ON a.channel = 'catalog' AND a.channel_sk = cc.cc_call_center_sk
 LEFT JOIN store st ON a.channel = 'store' AND a.channel_sk = st.s_store_sk
 LEFT JOIN web_site ws_site ON a.channel = 'web' AND a.channel_sk = ws_site.web_site_sk
)
SELECT
  sale_date,
  year,
  month,
  day_name,
  product_name,
  channel,
  channel_entity_name,
  total_qty,
  total_sales,
  total_profit,
  avg_discount,
  promo_cost_total,
  distinct_channels,
  sales_rank
FROM ranked_sales
WHERE (total_sales > 10000 OR total_qty > 100)
  AND (sales_rank <= 10 OR channel = 'ALL')
ORDER BY year, month, day_name, channel, sales_rank
