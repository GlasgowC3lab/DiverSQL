WITH joined_data AS (
   SELECT
       cc.cc_call_center_id,
       cp.cp_catalog_page_number,
       sm.sm_type,
       p.p_promo_name,
       r.r_reason_desc,
       wp.wp_type,
       td.t_hour,
       cs.cs_sold_date_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       cr.cr_return_amount,
       wr.wr_return_amt,
       l.total_sales_same_day
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN web_returns wr
     ON wr.wr_reason_sk = r.r_reason_sk
   LEFT JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   CROSS JOIN LATERAL (
       SELECT sum(cs2.cs_ext_sales_price) AS total_sales_same_day
       FROM catalog_sales cs2
       WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
   ) l
   WHERE cc.cc_rec_end_date = DATE '2001-12-31'
     AND cc.cc_suite_number LIKE 'Suite %'
     AND cp.cp_catalog_page_number IN (9, 14)
     AND wp.wp_type = 'dynamic'
     AND sm.sm_type = 'AIR'
     AND td.t_hour BETWEEN 8 AND 17
     AND hd.hd_vehicle_count > 1
),
aggregated AS (
   SELECT
       cc_call_center_id,
       cp_catalog_page_number,
       SUM(cs_ext_sales_price) AS sum_sales,
       AVG(cr_return_amount) AS avg_return_amount,
       SUM(cs_net_profit) AS sum_profit,
       SUM(total_sales_same_day) AS sum_total_sales_same_day
   FROM joined_data
   GROUP BY cc_call_center_id, cp_catalog_page_number
)
SELECT
   cc_call_center_id,
   cp_catalog_page_number,
   sum_sales,
   sum_profit,
   avg_return_amount,
   SUM(sum_sales) OVER (PARTITION BY cc_call_center_id ORDER BY cp_catalog_page_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales,
   RANK() OVER (ORDER BY sum_sales DESC) AS sales_rank
FROM aggregated
WHERE sum_sales > 10000
ORDER BY sum_sales DESC
LIMIT 100
