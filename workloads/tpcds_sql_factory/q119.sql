WITH returns_daily AS (
  SELECT d.d_date,
         SUM(cr.cr_net_loss) AS total_return_loss
  FROM date_dim d
  JOIN catalog_returns cr ON d.d_date_sk = cr.cr_returned_date_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  GROUP BY d.d_date
),
sales_daily_site AS (
  SELECT d.d_date,
         w.web_name,
         SUM(ws.ws_net_profit) AS total_sales_profit
  FROM date_dim d
  JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  GROUP BY d.d_date, w.web_name
),
combined AS (
  SELECT s.d_date,
         s.web_name,
         COALESCE(r.total_return_loss, 0) AS total_return_loss,
         s.total_sales_profit
  FROM sales_daily_site s
  LEFT JOIN returns_daily r ON s.d_date = r.d_date
)
SELECT d_date,
       web_name,
       total_return_loss,
       total_sales_profit,
       CASE WHEN total_sales_profit = 0 THEN NULL ELSE total_return_loss / total_sales_profit END AS loss_to_profit_ratio,
       LAG(total_return_loss) OVER (PARTITION BY web_name ORDER BY d_date) AS prev_day_return_loss,
       LEAD(total_sales_profit) OVER (PARTITION BY web_name ORDER BY d_date) AS next_day_sales_profit,
       AVG(total_sales_profit) OVER (PARTITION BY web_name ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7day_ma,
       CASE
         WHEN total_sales_profit > AVG(total_sales_profit) OVER (PARTITION BY web_name ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) THEN 'UP'
         ELSE 'DOWN'
       END AS profit_trend_7d
FROM combined
ORDER BY web_name, d_date
LIMIT 200
