WITH
  returned_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 100
  ),
  profitable_customers AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_net_profit > 50
  ),
  common_customers AS (
    SELECT cust_sk FROM returned_customers
    INTERSECT
    SELECT cust_sk FROM profitable_customers
  ),
  detailed AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      ws.ws_net_profit,
      cust.c_customer_sk,
      cust.c_customer_id,
      cp.cp_catalog_page_number,
      dr1.d_year,
      s.s_store_name,
      ti1.t_am_pm,
      hd_ref.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN date_dim dr1
      ON cr.cr_returned_date_sk = dr1.d_date_sk
    JOIN time_dim ti1
      ON cr.cr_returned_time_sk = ti1.t_time_sk
    JOIN customer cust
      ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dr2
      ON cp.cp_start_date_sk = dr2.d_date_sk
    JOIN date_dim dr3
      ON cp.cp_end_date_sk = dr3.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = dr1.d_date_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = dr1.d_date_sk
    JOIN time_dim ti2
      ON ws.ws_sold_time_sk = ti2.t_time_sk
    JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
      ON ib.ib_income_band_sk = hd_ref.hd_income_band_sk
  )
SELECT
  d_year,
  s_store_name,
  cp_catalog_page_number,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT cr_order_number) AS distinct_orders,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  MIN(ib_lower_bound) AS min_income_lower,
  MAX(ib_upper_bound) AS max_income_upper
FROM detailed
WHERE c_customer_sk IN (SELECT cust_sk FROM common_customers)
GROUP BY CUBE (d_year, s_store_name, cp_catalog_page_number)
ORDER BY total_return_amount DESC, d_year
LIMIT 100
