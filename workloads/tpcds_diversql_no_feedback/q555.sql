WITH sales_agg AS (
  SELECT
    c.c_customer_id AS c_customer_id,
    d_sold.d_year AS d_year,
    i.i_category AS i_category,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    SUM(ib.ib_upper_bound) AS total_income_upper
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d_sold.d_date_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_date >= DATE '2001-01-01'
    AND i.i_wholesale_cost > 1.00
    AND ib.ib_upper_bound < 50000
  GROUP BY CUBE (c.c_customer_id, d_sold.d_year, i.i_category)
)
SELECT *
FROM (
   SELECT
     c_customer_id,
     d_year,
     i_category,
     total_net_paid,
     total_return_amount,
     total_store_return,
     total_web_return,
     (total_net_paid - total_return_amount - total_store_return - total_web_return) AS net_after_returns,
     CASE WHEN total_net_paid > 0 THEN (total_return_amount + total_store_return + total_web_return) / total_net_paid ELSE NULL END AS return_rate
   FROM sales_agg
   WHERE total_net_paid > 1000
) a
UNION
SELECT *
FROM (
   SELECT
     c_customer_id,
     d_year,
     i_category,
     total_net_paid,
     total_return_amount,
     total_store_return,
     total_web_return,
     (total_net_paid - total_return_amount - total_store_return - total_web_return) AS net_after_returns,
     CASE WHEN total_net_paid > 0 THEN (total_return_amount + total_store_return + total_web_return) / total_net_paid ELSE NULL END AS return_rate
   FROM sales_agg
   WHERE total_return_amount > 500
) b
ORDER BY net_after_returns DESC
LIMIT 100
