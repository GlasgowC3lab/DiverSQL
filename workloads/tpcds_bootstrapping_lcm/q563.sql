SELECT
  d.d_year,
  s.s_state,
  CASE WHEN s.s_state IN ('CA', 'NY') THEN 'Coastal' ELSE 'Non-Coastal' END AS region_category,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
  SUM(cs.cs_ext_discount_amt) AS total_discount_amt,
  SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_discount_amt) AS net_sales,
  AVG(cs.cs_quantity) AS avg_quantity,
  SUM(cs.cs_quantity) AS total_quantity,
  SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
  SUM(cs.cs_ext_tax) AS total_tax,
  SUM(cs.cs_ext_sales_price) * 0.1 AS ten_percent_of_sales,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(wr.wr_net_loss) AS total_web_return_loss,
  (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_return_loss,
  CASE
    WHEN SUM(cs.cs_net_paid) = 0 THEN NULL
    ELSE (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) / SUM(cs.cs_net_paid)
  END AS return_loss_ratio,
  CASE
    WHEN SUM(cs.cs_net_paid) = 0 THEN NULL
    ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
  END AS profit_margin
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
  AND cs.cs_ship_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
  AND sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2002
  AND s.s_state IS NOT NULL
GROUP BY d.d_year, s.s_state
HAVING SUM(cs.cs_net_paid) > 50000
ORDER BY d.d_year, s.s_state
