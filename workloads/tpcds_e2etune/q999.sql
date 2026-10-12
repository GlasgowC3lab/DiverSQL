WITH agg AS (
  SELECT
    ws_site.web_name AS website_name,
    td.t_hour AS hour_of_day,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_buyers,
    COUNT(DISTINCT ws.ws_ship_customer_sk) AS distinct_shippers,
    COUNT(DISTINCT CASE WHEN cd_ship.cd_gender = 'F' THEN ws.ws_ship_customer_sk END) AS distinct_female_shippers,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    SUM(ws.ws_coupon_amt) AS total_coupon_amount
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  WHERE cd_bill.cd_gender = 'M'
    AND cd_bill.cd_marital_status = 'M'
    AND ws_site.web_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 21
    AND ws.ws_coupon_amt > 0
  GROUP BY ws_site.web_name, td.t_hour
),
ranked AS (
  SELECT
    website_name,
    hour_of_day,
    order_cnt,
    total_net_profit,
    total_sales,
    avg_discount,
    distinct_buyers,
    distinct_shippers,
    distinct_female_shippers,
    total_quantity,
    total_ship_cost,
    total_coupon_amount,
    RANK() OVER (PARTITION BY website_name ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY website_name ORDER BY hour_of_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_profit
  FROM agg
)
SELECT *
FROM ranked
WHERE profit_rank <= 5
ORDER BY website_name, profit_rank
