WITH
joined_data AS (
  SELECT
    d_sold.d_year,
    i.i_category,
    cs.cs_net_paid,
    cr.cr_return_amount,
    c_bill.c_customer_id,
    i.i_current_price,
    ss.ss_ticket_number
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN date_dim d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
  JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
  JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
  WHERE
    d_sold.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND sm.sm_carrier = 'MSC'
    AND EXISTS (
      SELECT 1 FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cs.cs_order_number
        AND cr2.cr_return_amount > 100
    )
)
SELECT
  d_year,
  i_category,
  SUM(cs_net_paid) AS total_net_paid,
  SUM(cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  AVG(i_current_price) AS avg_price
FROM joined_data
GROUP BY GROUPING SETS (
  (d_year, i_category),
  (d_year),
  (i_category),
  ()
)
LIMIT 100
