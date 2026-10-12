WITH filtered_sales AS (
  SELECT
    ws.ws_warehouse_sk,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_net_paid
  FROM web_sales ws
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE ca.ca_county = 'Maricopa County'
    AND ws.ws_sold_date_sk BETWEEN 2451080 AND 2451110
    AND ws.ws_net_profit > 0
),
agg AS (
  SELECT
    w.w_state AS warehouse_state,
    wsit.web_city AS web_site_city,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_quantity) AS total_quantity,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_ext_discount_amt) AS avg_discount_amt
  FROM filtered_sales fs
  JOIN warehouse w
    ON fs.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site wsit
    ON fs.ws_web_site_sk = wsit.web_site_sk
  GROUP BY w.w_state, wsit.web_city
  HAVING SUM(fs.ws_net_profit) > 10000
)
SELECT
  warehouse_state,
  web_site_city,
  order_cnt,
  total_quantity,
  total_net_profit,
  avg_discount_amt,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 10
