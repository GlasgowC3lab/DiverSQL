WITH web_sales_monthly AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS cnt_sales,
    AVG(ws.ws_net_profit) AS avg_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE c.c_birth_country = 'ETHIOPIA'
    AND cd.cd_marital_status = 'M'
    AND d.d_year = 2020
    AND wp.wp_type = 'product'
  GROUP BY d.d_year, d.d_moy
),
store_returns_monthly AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS cnt_returns,
    AVG(sr.sr_net_loss) AS avg_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE c.c_birth_country = 'ETHIOPIA'
    AND cd.cd_marital_status = 'M'
    AND d.d_year = 2020
  GROUP BY d.d_year, d.d_moy
)
SELECT
  COALESCE(ws.year, sr.year) AS year,
  COALESCE(ws.month, sr.month) AS month,
  ws.avg_net_profit,
  sr.avg_net_loss,
  CASE 
    WHEN sr.avg_net_loss IS NULL OR sr.avg_net_loss = 0 THEN NULL
    ELSE ws.avg_net_profit / sr.avg_net_loss
  END AS profit_to_loss_ratio,
  RANK() OVER (ORDER BY ws.avg_net_profit DESC NULLS LAST) AS profit_rank
FROM web_sales_monthly ws
FULL OUTER JOIN store_returns_monthly sr
  ON ws.year = sr.year AND ws.month = sr.month
ORDER BY year, month
