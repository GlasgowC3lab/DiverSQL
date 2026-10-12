WITH store_purchasers AS (
    SELECT DISTINCT c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE i.i_category_id = 1
      AND s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
),
web_purchasers AS (
    SELECT DISTINCT c.c_customer_id AS customer_id
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE i.i_category_id = 1
      AND wsite.web_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT customer_id
FROM store_purchasers
INTERSECT
SELECT customer_id
FROM web_purchasers
ORDER BY customer_id
LIMIT 100
