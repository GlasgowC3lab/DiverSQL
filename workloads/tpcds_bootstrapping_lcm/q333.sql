SELECT
  s.s_store_id,
  s.s_store_name,
  s.s_city,
  s.s_state,
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_city,
  d_sales.d_year,
  d_sales.d_month_seq,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_net_profit) AS total_profit,
  AVG(ss.ss_sales_price) AS avg_sales_price,
  SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  MIN(d_sales.d_date) AS first_sale_date,
  MAX(d_sales.d_date) AS last_sale_date,
  CASE
    WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
    ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
  END AS profit_margin
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_close
  ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d_sales.d_date_sk
JOIN date_dim d_inv
  ON i.inv_date_sk = d_inv.d_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_close
  ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
  AND cc.cc_state = 'CA'
  AND d_cc_close.d_date >= d_sales.d_date
GROUP BY
  s.s_store_id,
  s.s_store_name,
  s.s_city,
  s.s_state,
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_city,
  d_sales.d_year,
  d_sales.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
