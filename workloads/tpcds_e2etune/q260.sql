WITH sales_monthly AS (
  SELECT
    d.d_year,
    d.d_moy,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_store_sk) AS distinct_store_cnt,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(*) AS transaction_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND d.d_moy IN (1, 2, 3, 4, 5)
  GROUP BY d.d_year, d.d_moy
),
websites_monthly AS (
  SELECT
    d_open.d_year,
    d_open.d_moy,
    COUNT(DISTINCT ws.web_site_id) AS website_open_cnt,
    COUNT(DISTINCT CASE WHEN ws.web_close_date_sk IS NOT NULL THEN ws.web_site_id END) AS website_closed_cnt
  FROM web_site ws
  JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
  LEFT JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
  WHERE d_open.d_year BETWEEN 1999 AND 2001
    AND d_open.d_moy IN (1, 2, 3, 4, 5)
  GROUP BY d_open.d_year, d_open.d_moy
)
SELECT
  s.d_year,
  s.d_moy,
  s.total_net_profit,
  s.avg_discount,
  s.distinct_store_cnt,
  s.total_quantity,
  s.transaction_cnt,
  w.website_open_cnt,
  w.website_closed_cnt,
  RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_monthly s
JOIN websites_monthly w
  ON s.d_year = w.d_year AND s.d_moy = w.d_moy
ORDER BY s.total_net_profit DESC
LIMIT 20
