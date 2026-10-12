WITH agg AS (
  SELECT
    p.p_promo_name,
    d_sold.d_quarter_name AS quarter,
    d_sold.d_year AS d_year,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS order_count
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
  WHERE d_sold.d_year = 1902
    AND d_sold.d_holiday = 'N'
    AND p.p_discount_active = 'Y'
    AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  GROUP BY p.p_promo_name, d_sold.d_quarter_name, d_sold.d_year
)
SELECT
  p_promo_name,
  quarter,
  d_year,
  total_net_profit,
  total_sales,
  avg_discount,
  order_count,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_by_year
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
