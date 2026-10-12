WITH union_data AS (
    SELECT c.c_customer_id,
           ws.ws_ship_hdemo_sk,
           ws.ws_net_paid_inc_ship_tax
    FROM tpcds.customer c
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE c.c_birth_month = 4
      AND c.c_last_review_date >= 2452540
      AND ws.ws_ship_hdemo_sk IN (5705, 3343)
      AND wr.wr_account_credit > 200.00
      AND ws.ws_item_sk IN (
          SELECT wr2.wr_item_sk
          FROM tpcds.web_returns wr2
          WHERE wr2.wr_return_amt > 150.00
      )
    UNION DISTINCT
    SELECT c.c_customer_id,
           ws.ws_ship_hdemo_sk,
           ws.ws_net_paid_inc_ship_tax
    FROM tpcds.customer c
    JOIN tpcds.web_sales ws
      ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE c.c_birth_month = 9
      AND c.c_last_review_date <= 2452634
      AND ws.ws_ship_hdemo_sk IN (4106, 5162)
      AND wr.wr_account_credit < 300.00
      AND ws.ws_item_sk IN (
          SELECT wr2.wr_item_sk
          FROM tpcds.web_returns wr2
          WHERE wr2.wr_return_amt > 150.00
      )
)
SELECT
    c_customer_id,
    ws_ship_hdemo_sk,
    SUM(ws_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(ws_net_paid_inc_ship_tax) AS avg_net_paid,
    COUNT(*) AS transaction_cnt,
    MIN(ws_net_paid_inc_ship_tax) AS min_net_paid,
    MAX(ws_net_paid_inc_ship_tax) AS max_net_paid
FROM union_data
GROUP BY GROUPING SETS (
    (c_customer_id, ws_ship_hdemo_sk),
    (c_customer_id),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
