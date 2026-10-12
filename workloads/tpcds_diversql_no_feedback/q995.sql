WITH ss_joined AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_net_paid,
    ss.ss_ext_list_price,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    p.p_promo_name,
    p.p_promo_sk
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca_cur
    ON c.c_current_addr_sk = ca_cur.ca_address_sk
  WHERE ss.ss_customer_sk IN (
    SELECT c2.c_customer_sk
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
  )
),
ws_joined AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_net_paid,
    ws.ws_ext_list_price,
    c_bill.c_customer_sk AS bill_customer_sk,
    c_bill.c_first_name AS bill_first_name,
    ca_bill.ca_state AS bill_state,
    c_ship.c_customer_sk AS ship_customer_sk,
    ca_ship.ca_state AS ship_state,
    p.p_promo_name,
    p.p_promo_sk
  FROM web_sales ws
  JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT
  COALESCE(ss.p_promo_name, ws.p_promo_name) AS promo_name,
  COALESCE(ss.ca_state, ws.bill_state) AS state,
  SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
  COUNT(DISTINCT COALESCE(ss.c_customer_sk, ws.bill_customer_sk)) AS distinct_customers,
  AVG(COALESCE(ss.ss_ext_list_price, ws.ws_ext_list_price)) AS avg_ext_list_price
FROM ss_joined ss
FULL OUTER JOIN ws_joined ws
  ON ss.p_promo_sk = ws.p_promo_sk
GROUP BY
  COALESCE(ss.p_promo_name, ws.p_promo_name),
  COALESCE(ss.ca_state, ws.bill_state)
ORDER BY total_net_paid DESC
LIMIT 100
