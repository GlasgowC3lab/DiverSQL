WITH sales_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_coupon_amt,
    ws.ws_sold_time_sk,
    ws.ws_web_page_sk,
    ws.ws_sold_date_sk,
    t.t_hour,
    c.c_preferred_cust_flag,
    wp.wp_type
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    AND c.c_preferred_cust_flag = 'Y'
    AND wp.wp_type = 'product'
),
hourly_agg AS (
  SELECT
    sd.t_hour,
    COUNT(DISTINCT sd.ws_order_number) AS order_cnt,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    SUM(sd.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(r.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(r.wr_return_quantity, 0)) AS total_return_qty,
    SUM(sd.ws_quantity) AS total_qty,
    AVG(sd.ws_coupon_amt) AS avg_coupon_amt
  FROM sales_data sd
  LEFT JOIN web_returns r
    ON sd.ws_order_number = r.wr_order_number
    AND sd.ws_item_sk = r.wr_item_sk
  GROUP BY sd.t_hour
  HAVING SUM(sd.ws_ext_sales_price) > 5000
)
SELECT
  t_hour,
  order_cnt,
  total_sales,
  total_net_profit,
  total_return_amount,
  total_return_qty,
  CASE WHEN total_qty = 0 THEN 0 ELSE total_return_qty / CAST(total_qty AS DOUBLE) END AS return_rate,
  avg_coupon_amt,
  RANK() OVER (ORDER BY (total_net_profit - total_return_amount) DESC) AS profit_rank
FROM hourly_agg
ORDER BY profit_rank
LIMIT 10
