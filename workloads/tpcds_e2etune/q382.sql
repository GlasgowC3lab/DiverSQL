WITH sales AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_customer_sk,
    ss.ss_addr_sk,
    ss.ss_item_sk,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_net_profit,
    ss.ss_net_paid,
    ss.ss_sold_date_sk
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_month = 6
    AND ca.ca_state = 'CA'
),
returns AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_customer_sk,
    sr.sr_addr_sk,
    sr.sr_item_sk,
    sr.sr_ticket_number,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    sr.sr_return_amt
  FROM store_returns sr
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_month = 6
    AND ca.ca_state = 'CA'
)
SELECT
  s.ss_store_sk,
  ca.ca_city,
  SUM(s.ss_net_profit) AS total_sales_profit,
  COALESCE(SUM(r.sr_net_loss), 0) AS total_return_loss,
  SUM(s.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) AS net_profit_after_returns,
  SUM(s.ss_quantity) AS total_quantity_sold,
  COALESCE(SUM(r.sr_return_quantity), 0) AS total_return_quantity,
  CASE WHEN SUM(s.ss_quantity) = 0 THEN 0
       ELSE COALESCE(SUM(r.sr_return_quantity), 0) / SUM(s.ss_quantity) END AS return_rate,
  RANK() OVER (ORDER BY SUM(s.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
  ON s.ss_ticket_number = r.sr_ticket_number
  AND s.ss_item_sk = r.sr_item_sk
JOIN customer_address ca
  ON s.ss_addr_sk = ca.ca_address_sk
GROUP BY s.ss_store_sk, ca.ca_city
HAVING SUM(s.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
