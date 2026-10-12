WITH sales_qtr AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         d.d_year,
         d.d_quarter_name,
         SUM(ws.ws_net_profit) AS sales_profit,
         SUM(ws.ws_ext_sales_price) AS sales_volume
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_web_site_sk, d.d_year, d.d_quarter_name
),
returns_qtr AS (
  SELECT w.web_site_sk AS site_sk,
         d_ret.d_year,
         d_ret.d_quarter_name,
         SUM(cr.cr_net_loss) AS returns_loss,
         COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN web_site w ON 1=1
  JOIN date_dim d_open ON w.web_open_date_sk = d_open.d_date_sk
  JOIN date_dim d_close ON w.web_close_date_sk = d_close.d_date_sk
  WHERE d_ret.d_date BETWEEN d_open.d_date AND d_close.d_date
  GROUP BY w.web_site_sk, d_ret.d_year, d_ret.d_quarter_name
)
SELECT w.web_name,
       s.d_year,
       s.d_quarter_name,
       s.sales_profit,
       COALESCE(r.returns_loss, 0) AS returns_loss,
       s.sales_profit - COALESCE(r.returns_loss, 0) AS net_profit,
       CASE
         WHEN s.sales_profit - COALESCE(r.returns_loss, 0) > 1000000 THEN 'Platinum'
         WHEN s.sales_profit - COALESCE(r.returns_loss, 0) > 500000 THEN 'Gold'
         WHEN s.sales_profit - COALESCE(r.returns_loss, 0) > 100000 THEN 'Silver'
         ELSE 'Bronze'
       END AS net_profit_tier,
       DENSE_RANK() OVER (PARTITION BY s.d_year ORDER BY s.sales_profit - COALESCE(r.returns_loss, 0) DESC) AS profit_rank_year,
       ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.sales_profit DESC) AS sales_rank_year,
       PERCENT_RANK() OVER (ORDER BY s.sales_profit - COALESCE(r.returns_loss, 0)) AS overall_percentile
FROM sales_qtr s
LEFT JOIN returns_qtr r
  ON s.site_sk = r.site_sk AND s.d_year = r.d_year AND s.d_quarter_name = r.d_quarter_name
JOIN web_site w ON s.site_sk = w.web_site_sk
WHERE s.d_year BETWEEN 2020 AND 2023
ORDER BY s.d_year, net_profit DESC
LIMIT 100
