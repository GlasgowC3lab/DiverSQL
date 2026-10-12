WITH
store_agg AS (
   SELECT ss_item_sk,
          ss_sold_date_sk,
          ss_sold_time_sk,
          ss_promo_sk,
          SUM(ss_net_paid) AS store_net_paid,
          SUM(ss_quantity) AS store_qty
   FROM store_sales
   WHERE ss_sold_date_sk BETWEEN 2415000 AND 2416000
     AND ss_quantity > 0
   GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk, ss_promo_sk
),
web_agg AS (
   SELECT ws_item_sk,
          ws_sold_date_sk,
          ws_sold_time_sk,
          ws_web_site_sk,
          ws_promo_sk,
          ws_order_number,
          SUM(ws_net_paid) AS web_net_paid,
          SUM(ws_quantity) AS web_qty
   FROM web_sales
   WHERE ws_sold_date_sk BETWEEN 2415000 AND 2416000
     AND ws_quantity > 0
   GROUP BY ws_item_sk, ws_sold_date_sk, ws_sold_time_sk, ws_web_site_sk, ws_promo_sk, ws_order_number
),
catalog_key_set AS (
   SELECT cr_order_number AS order_key
   FROM catalog_returns
   WHERE cr_return_amount > 100
),
web_key_set AS (
   SELECT ws_order_number AS order_key
   FROM web_sales
   WHERE ws_net_paid > 200
),
except_set AS (
   SELECT order_key FROM catalog_key_set
   EXCEPT
   SELECT order_key FROM web_key_set
),
intersect_set AS (
   SELECT order_key FROM catalog_key_set
   INTERSECT
   SELECT order_key FROM web_key_set
)
SELECT
   d.d_year,
   i.i_category,
   p.p_promo_name,
   SUM(coalesce(sa.store_net_paid, 0) + coalesce(wa.web_net_paid, 0)) AS total_net_paid,
   SUM(coalesce(sa.store_qty, 0) + coalesce(wa.web_qty, 0)) AS total_units,
   COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
   COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
   COUNT(DISTINCT CASE WHEN es.order_key IS NOT NULL THEN es.order_key END) AS except_orders,
   COUNT(DISTINCT CASE WHEN iset.order_key IS NOT NULL THEN iset.order_key END) AS intersect_orders
FROM store_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN time_dim td1 ON sa.ss_sold_time_sk = td1.t_time_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_agg wa ON wa.ws_item_sk = i.i_item_sk
                     AND wa.ws_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim td2 ON wa.ws_sold_time_sk = td2.t_time_sk
LEFT JOIN web_site ws ON wa.ws_web_site_sk = ws.web_site_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                              AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_returned_date_sk = d.d_date_sk
                         AND wr.wr_order_number = wa.ws_order_number
LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
LEFT JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
LEFT JOIN except_set es ON es.order_key = cr.cr_order_number
LEFT JOIN intersect_set iset ON iset.order_key = cr.cr_order_number
WHERE d.d_year = 2001
  AND p.p_channel_tv = 'Y'
  AND ws.web_open_date_sk = d.d_date_sk
  AND cc.cc_state = 'CA'
  AND r.r_reason_desc LIKE '%damage%'
GROUP BY ROLLUP (d.d_year, i.i_category, p.p_promo_name)
ORDER BY total_net_paid DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
