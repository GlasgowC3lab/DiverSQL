WITH sales_agg AS (
   SELECT
      d.d_year,
      i.i_brand,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
   FROM date_dim d
   JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                        AND wr.wr_order_number = ws.ws_order_number
   JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON i.i_item_sk = ws.ws_item_sk
   JOIN household_demographics hd ON hd.hd_demo_sk = ws.ws_bill_hdemo_sk
   JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
   JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
   JOIN time_dim t ON t.t_time_sk = ws.ws_sold_time_sk
   WHERE d.d_year = 2001
     AND cc.cc_state = 'CA'
     AND ib.ib_lower_bound >= 60000
     AND i.i_current_price > 20
     AND wr.wr_return_quantity > 5
     AND i.i_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 5)
   GROUP BY d.d_year, i.i_brand
),
ranked_sales AS (
   SELECT
      d_year,
      i_brand,
      total_net_paid,
      orders_cnt,
      ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS brand_rank
   FROM sales_agg
)
SELECT
   d_year,
   i_brand,
   total_net_paid,
   orders_cnt,
   brand_rank
FROM ranked_sales
WHERE brand_rank <= 5
ORDER BY d_year, total_net_paid DESC
LIMIT 100
