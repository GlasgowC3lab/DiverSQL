WITH sales_state_month AS (
  SELECT ca.ca_state,
         cs.cs_sold_date_sk / 10000 AS year,
         (cs.cs_sold_date_sk % 10000) / 100 AS month,
         SUM(cs.cs_net_paid_inc_ship_tax) AS paid_inc_ship_tax,
         SUM(cs.cs_net_profit) AS profit,
         COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  GROUP BY ca.ca_state, cs.cs_sold_date_sk / 10000, (cs.cs_sold_date_sk % 10000) / 100
),
returns_state_month AS (
  SELECT ca.ca_state,
         sr.sr_returned_date_sk / 10000 AS year,
         (sr.sr_returned_date_sk % 10000) / 100 AS month,
         SUM(sr.sr_return_amt_inc_tax) AS return_amt,
         SUM(sr.sr_net_loss) AS loss,
         COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  GROUP BY ca.ca_state, sr.sr_returned_date_sk / 10000, (sr.sr_returned_date_sk % 10000) / 100
)
SELECT s.ca_state,
       s.year,
       s.month,
       s.profit,
       s.paid_inc_ship_tax,
       COALESCE(r.return_amt, 0) AS return_amt,
       COALESCE(r.loss, 0) AS loss,
       (s.paid_inc_ship_tax - COALESCE(r.return_amt, 0)) AS net_sales,
       PERCENT_RANK() OVER (PARTITION BY s.year ORDER BY (s.profit - COALESCE(r.loss, 0))) AS profit_percentile,
       CASE WHEN s.sales_cnt > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM sales_state_month s
LEFT JOIN returns_state_month r ON s.ca_state = r.ca_state AND s.year = r.year AND s.month = r.month
WHERE s.year = 2022
ORDER BY net_sales DESC
LIMIT 200
