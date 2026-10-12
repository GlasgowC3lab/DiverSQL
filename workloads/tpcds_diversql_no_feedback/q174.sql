WITH store_agg AS (
  SELECT
    c.c_customer_id AS customer_id,
    ca.ca_state AS state,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*) AS txn_count
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ss.ss_item_sk IN (105717, 113745)
  GROUP BY c.c_customer_id, ca.ca_state
),
web_agg AS (
  SELECT
    c.c_customer_id AS customer_id,
    ca.ca_state AS state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS txn_count
  FROM web_sales ws
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE ws.ws_item_sk IN (105717, 113745)
  GROUP BY c.c_customer_id, ca.ca_state
),
union_all AS (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
)
SELECT
  customer_id,
  state,
  total_net_paid,
  txn_count,
  SUM(total_net_paid) OVER (ORDER BY total_net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
FROM union_all
ORDER BY total_net_paid DESC
LIMIT 100
