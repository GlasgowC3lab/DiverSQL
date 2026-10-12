WITH returns_daily AS (
  SELECT d.d_date,
         d.d_year,
         d.d_month_seq,
         SUM(cr.cr_net_loss) AS total_return_loss,
         SUM(cr.cr_return_quantity) AS total_return_qty
  FROM date_dim d
  JOIN catalog_returns cr ON d.d_date_sk = cr.cr_returned_date_sk
  WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  GROUP BY d.d_date, d.d_year, d.d_month_seq
),
sales_daily_site AS (
  SELECT d.d_date,
         d.d_year,
         d.d_month_seq,
         w.web_name,
         SUM(ws.ws_net_profit) AS total_sales_profit
  FROM date_dim d
  JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  GROUP BY d.d_date, d.d_year, d.d_month_seq, w.web_name
)
SELECT r.d_date,
       r.d_year,
       r.d_month_seq,
       s.web_name,
       r.total_return_loss,
       r.total_return_qty,
       s.total_sales_profit,
       CASE WHEN r.total_return_loss > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
       RANK() OVER (PARTITION BY r.d_date ORDER BY r.total_return_loss DESC) AS loss_rank_per_day
FROM returns_daily r
LEFT JOIN sales_daily_site s
  ON r.d_date = s.d_date
 AND r.d_year = s.d_year
 AND r.d_month_seq = s.d_month_seq
ORDER BY r.d_date, loss_rank_per_day
LIMIT 200
