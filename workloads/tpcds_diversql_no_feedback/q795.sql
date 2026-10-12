WITH base AS (
   SELECT
       s.s_store_id,
       wsite.web_site_id,
       cc.cc_call_center_id,
       d.d_year,
       t.t_shift,
       cd.cd_gender,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       cr.cr_return_amount,
       ws.ws_net_paid,
       ws.ws_ext_sales_price
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND t.t_shift IN ('first', 'second')
     AND cd.cd_gender = 'F'
     AND ib.ib_upper_bound <= 80000
     AND wsite.web_state = 'TX'
     AND cc.cc_company = 5
),
agg AS (
   SELECT
       s_store_id,
       web_site_id,
       cc_call_center_id,
       d_year,
       SUM(cr_return_amount) AS sum_return_amount,
       SUM(ws_net_paid) AS sum_sales,
       COUNT(*) AS cnt_txn
   FROM base
   GROUP BY
       s_store_id,
       web_site_id,
       cc_call_center_id,
       d_year
)
SELECT
   a.s_store_id,
   a.web_site_id,
   a.cc_call_center_id,
   a.d_year,
   a.sum_return_amount,
   a.sum_sales,
   a.cnt_txn,
   a.sum_return_amount / NULLIF(a.cnt_txn, 0) AS avg_return_per_txn,
   v.day_name
FROM agg a
CROSS JOIN (VALUES ROW('Mon'), ROW('Tue'), ROW('Wed')) AS v(day_name)
WHERE a.sum_sales > 5000
  AND a.cnt_txn >= 10
ORDER BY avg_return_per_txn DESC
LIMIT 100
