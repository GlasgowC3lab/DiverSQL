WITH
  first_part AS (
    SELECT
      ws.ws_order_number                              AS order_id,
      ca_bill.ca_state                               AS bill_state,
      ca_ship.ca_state                               AS ship_state,
      sm1.sm_type                                    AS ship_type,
      t_sold.t_meal_time                             AS meal_time,
      ws.ws_quantity,
      ws.ws_ext_discount_amt,
      ws.ws_net_profit,
      -- expand an array of two numeric metrics per row
      u.metric,
      -- scalar sub‑query: total discount for the whole order
      (SELECT SUM(ws2.ws_ext_discount_amt)
         FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number) AS total_order_discount
    FROM web_sales ws
    JOIN time_dim t_sold          ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN time_dim t_sold_dup      ON ws.ws_sold_time_sk = t_sold_dup.t_time_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_bill_dup ON ws.ws_bill_addr_sk = ca_bill_dup.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm1           ON ws.ws_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN ship_mode sm2           ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN UNNEST(ARRAY[ws.ws_quantity, CAST(ws.ws_ext_discount_amt AS double)]) AS u(metric) ON TRUE
    WHERE ca_bill.ca_location_type = 'single family'
  ),
  second_part AS (
    SELECT
      sr.sr_ticket_number                             AS order_id,
      ca_return.ca_state                              AS return_state,
      t_return.t_meal_time                            AS return_meal,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      -- expand an array of return quantity and amount per row
      v.metric,
      -- EXISTS sub‑query: does a matching web_sales order exist?
      CASE WHEN EXISTS (
        SELECT 1 FROM web_sales ws3 WHERE ws3.ws_order_number = sr.sr_ticket_number
      ) THEN 1 ELSE 0 END                               AS has_web_sale
    FROM store_returns sr
    FULL OUTER JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN customer_address ca_return   ON sr.sr_addr_sk = ca_return.ca_address_sk
    LEFT JOIN UNNEST(ARRAY[sr.sr_return_quantity, CAST(sr.sr_return_amt AS double)]) AS v(metric) ON TRUE
    WHERE t_return.t_am_pm = 'PM'
  ),
  united AS (
    SELECT
      order_id,
      ws_quantity,
      ws_ext_discount_amt,
      total_order_discount,
      NULL           AS return_quantity,
      NULL           AS return_amt,
      NULL           AS has_web_sale,
      meal_time,
      NULL           AS return_meal
    FROM first_part
    UNION DISTINCT
    SELECT
      order_id,
      NULL           AS ws_quantity,
      NULL           AS ws_ext_discount_amt,
      NULL           AS total_order_discount,
      sr_return_quantity,
      sr_return_amt,
      has_web_sale,
      NULL           AS meal_time,
      return_meal
    FROM second_part
  )
SELECT
  order_id,
  COUNT(*)                                     AS cnt,
  SUM(ws_quantity)                             AS total_quantity,
  SUM(ws_ext_discount_amt)                     AS total_discount,
  SUM(total_order_discount)                    AS sum_total_order_discount,
  SUM(return_quantity)                         AS total_return_quantity,
  SUM(return_amt)                              AS total_return_amount,
  SUM(has_web_sale)                            AS web_sale_matches,
  MIN(meal_time)                               AS any_meal_time,
  MIN(return_meal)                             AS any_return_meal
FROM united
GROUP BY order_id, meal_time, return_meal
ORDER BY cnt DESC
LIMIT 100
