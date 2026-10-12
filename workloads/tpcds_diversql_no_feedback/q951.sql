WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    s.s_state,
    d.d_year,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
FROM ss_sample AS ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
  AND ws.ws_sold_date_sk = d.d_date_sk
JOIN LATERAL (
    SELECT ws.ws_quantity * ws.ws_sales_price AS ws_line_total
) AS wl
  ON TRUE
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND ca.ca_country = 'United States'
    AND ss.ss_net_profit > 0
GROUP BY
    s.s_store_name,
    s.s_state,
    d.d_year,
    sm.sm_type
ORDER BY
    sales_rank,
    store_sales_amount DESC
LIMIT 100
