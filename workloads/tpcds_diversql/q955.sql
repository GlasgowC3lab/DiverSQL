WITH ss_sample AS (
  SELECT ss_ticket_number,
         ss_customer_sk,
         ss_item_sk,
         ss_quantity,
         ss_net_profit
  FROM store_sales
  TABLESAMPLE BERNOULLI (10)
  WHERE ss_sold_date_sk BETWEEN 2451910 AND 2451915
),
ws_sample AS (
  SELECT ws_order_number AS ticket_number,
         ws_bill_customer_sk AS customer_sk,
         ws_item_sk,
         ws_quantity,
         ws_net_profit
  FROM web_sales
  TABLESAMPLE BERNOULLI (10)
  WHERE ws_sold_date_sk BETWEEN 2451910 AND 2451915
),
intersect_keys AS (
  SELECT ss_ticket_number AS ticket_number
  FROM ss_sample
  INTERSECT
  SELECT ticket_number
  FROM ws_sample
),
union_set AS (
  SELECT i.i_item_id,
         c.c_customer_id,
         i.i_current_price,
         (SELECT SUM(ss2.ss_net_profit)
          FROM store_sales ss2
          WHERE ss2.ss_customer_sk = c.c_customer_sk) AS total_customer_profit
  FROM intersect_keys ik
  JOIN store_sales ss ON ss.ss_ticket_number = ik.ticket_number
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE ss.ss_quantity > 5
    AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
        )
  UNION
  SELECT i2.i_item_id,
         c2.c_customer_id,
         i2.i_current_price,
         (SELECT SUM(ws2.ws_net_profit)
          FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c2.c_customer_sk) AS total_customer_profit
  FROM intersect_keys ik2
  JOIN web_sales ws ON ws.ws_order_number = ik2.ticket_number
  JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
  JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
  WHERE ws.ws_quantity > 5
    AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i2.i_item_sk
            AND p2.p_discount_active = 'Y'
        )
)
SELECT i_item_id,
       c_customer_id,
       i_current_price,
       total_customer_profit
FROM union_set
ORDER BY i_item_id, c_customer_id
LIMIT 100
