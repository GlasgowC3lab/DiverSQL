WITH
date_range AS (
 SELECT d_date_sk
 FROM date_dim
 WHERE d_year = 2002
),
sales_agg AS (
 SELECT
   i.i_item_sk,
   i.i_item_id,
   i.i_item_desc,
   i.i_category,
   i.i_brand,
   COALESCE(SUM(cs.cs_net_paid),0) AS catalog_net_paid,
   COALESCE(SUM(ss.ss_net_paid),0) AS store_net_paid,
   COALESCE(SUM(ws.ws_net_paid),0) AS web_net_paid,
   COALESCE(SUM(cr.cr_net_loss),0) AS catalog_net_loss,
   COALESCE(SUM(sr.sr_net_loss),0) AS store_net_loss,
   COALESCE(SUM(wr.wr_net_loss),0) AS web_net_loss,
   COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
   COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
   COUNT(DISTINCT ws.ws_order_number) AS web_orders,
   AVG(cs.cs_ext_discount_amt) AS avg_cat_discount,
   AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
   AVG(ws.ws_ext_discount_amt) AS avg_web_discount
 FROM item i
 LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_range)
 LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_range)
 LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_range)
 LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk AND cr.cr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
 LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk AND sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
 LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk AND wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
 GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_category, i.i_brand
),
promo_agg AS (
 SELECT
   p.p_item_sk,
   COUNT(*) AS promo_cnt,
   SUM(p.p_cost) AS promo_total_cost,
   MAX(p.p_start_date_sk) AS latest_promo_start_sk,
   MIN(p.p_end_date_sk) AS earliest_promo_end_sk
 FROM promotion p
 WHERE p.p_start_date_sk IN (SELECT d_date_sk FROM date_range) OR p.p_end_date_sk IN (SELECT d_date_sk FROM date_range)
 GROUP BY p.p_item_sk
),
combined AS (
 SELECT
   s.i_item_sk,
   s.i_item_id,
   s.i_item_desc,
   s.i_category,
   s.i_brand,
   s.catalog_net_paid,
   s.store_net_paid,
   s.web_net_paid,
   s.catalog_net_loss,
   s.store_net_loss,
   s.web_net_loss,
   (s.catalog_net_paid - s.catalog_net_loss) AS catalog_net_rev,
   (s.store_net_paid - s.store_net_loss) AS store_net_rev,
   (s.web_net_paid - s.web_net_loss) AS web_net_rev,
   s.catalog_orders,
   s.store_orders,
   s.web_orders,
   COALESCE(p.promo_cnt,0) AS promo_cnt,
   COALESCE(p.promo_total_cost,0) AS promo_total_cost,
   CASE 
      WHEN ((s.catalog_net_paid - s.catalog_net_loss) + (s.store_net_paid - s.store_net_loss) + (s.web_net_paid - s.web_net_loss)) > 0 THEN 'POSITIVE' 
      ELSE 'NONPOSITIVE' 
   END AS revenue_flag,
   CONCAT(s.i_brand, '::', s.i_category) AS brand_category,
   ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY ((s.catalog_net_paid - s.catalog_net_loss) + (s.store_net_paid - s.store_net_loss) + (s.web_net_paid - s.web_net_loss)) DESC) AS cat_rank,
   ((s.catalog_net_paid - s.catalog_net_loss) + (s.store_net_paid - s.store_net_loss) + (s.web_net_paid - s.web_net_loss)) AS total_net_rev,
   (COALESCE(s.avg_cat_discount,0) + COALESCE(s.avg_store_discount,0) + COALESCE(s.avg_web_discount,0))/3.0 AS avg_overall_discount
 FROM sales_agg s
 LEFT JOIN promo_agg p ON s.i_item_sk = p.p_item_sk
)
SELECT
  c.brand_category,
  c.i_item_id,
  c.i_item_desc,
  c.i_category,
  c.i_brand,
  (c.catalog_orders + c.store_orders + c.web_orders) AS total_orders,
  c.catalog_net_rev,
  c.store_net_rev,
  c.web_net_rev,
  c.total_net_rev,
  ROUND(c.avg_overall_discount,2) AS avg_discount,
  c.promo_cnt,
  c.promo_total_cost,
  c.revenue_flag,
  c.cat_rank,
  (SELECT AVG(c2.avg_overall_discount) FROM combined c2 WHERE c2.i_brand = c.i_brand) AS brand_avg_discount
FROM combined c
WHERE c.total_net_rev > 0
  AND (c.promo_cnt > 0 OR c.avg_overall_discount IS NOT NULL)
ORDER BY c.total_net_rev DESC
LIMIT 50
