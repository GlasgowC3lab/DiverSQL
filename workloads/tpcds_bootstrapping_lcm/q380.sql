SELECT
  cc.cc_company_name,
  cc.cc_state,
  d.d_year,
  d.d_month_seq,
  s.s_store_name,
  s.s_city,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_ext_discount_amt) AS total_discount,
  SUM(ss.ss_net_profit) AS total_profit,
  SUM(wr.wr_return_amt_inc_tax) AS total_returns,
  SUM(wr.wr_net_loss) AS total_return_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  CASE
    WHEN SUM(ss.ss_ext_sales_price) > 0 THEN
      ROUND(100 * SUM(wr.wr_return_amt_inc_tax) / SUM(ss.ss_ext_sales_price), 2)
    ELSE NULL
  END AS return_rate_percent,
  (SUM(ss.ss_ext_sales_price) - SUM(wr.wr_return_amt_inc_tax)) AS net_revenue
FROM date_dim d
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
  AND ss.ss_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
GROUP BY
  cc.cc_company_name,
  cc.cc_state,
  d.d_year,
  d.d_month_seq,
  s.s_store_name,
  s.s_city
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY net_revenue DESC
LIMIT 100
