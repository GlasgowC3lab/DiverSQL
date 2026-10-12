WITH sales_with_date AS (
  SELECT
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_sales_price,
    p.p_channel_tv,
    DATE_PARSE(CAST(ws.ws_sold_date_sk AS VARCHAR), '%Y%m%d') AS sold_date,
    DATE_TRUNC('month', DATE_PARSE(CAST(ws.ws_sold_date_sk AS VARCHAR), '%Y%m%d')) AS month_start
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
),
monthly_channel AS (
  SELECT
    month_start,
    p_channel_tv,
    SUM(ws_net_profit) AS month_profit,
    SUM(ws_ext_discount_amt) AS month_discount,
    AVG(ws_sales_price) AS avg_sales_price
  FROM sales_with_date
  GROUP BY month_start, p_channel_tv
)
SELECT
  month_start,
  p_channel_tv,
  month_profit,
  month_discount,
  avg_sales_price,
  month_profit - LAG(month_profit) OVER (PARTITION BY p_channel_tv ORDER BY month_start) AS profit_change,
  SUM(month_profit) OVER (PARTITION BY p_channel_tv ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_profit,
  CASE WHEN month_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_indicator
FROM monthly_channel
ORDER BY month_start DESC, p_channel_tv
LIMIT 100
