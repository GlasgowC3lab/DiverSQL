WITH
  sub1 AS (
    SELECT
      cs.cs_order_number        AS order_id,
      cs.cs_net_paid            AS net_paid,
      i.i_item_id               AS i_item_id,
      sm.sm_carrier             AS sm_carrier,
      t.t_hour                  AS t_hour,
      ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS qty_price_arr
    FROM catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE sm.sm_carrier = 'PRIVATECARRIER'
  ),
  sub1_unnest AS (
    SELECT
      order_id,
      net_paid,
      i_item_id,
      sm_carrier,
      t_hour,
      u.value AS array_value
    FROM sub1
    CROSS JOIN UNNEST(qty_price_arr) AS u(value)
  ),
  sub2 AS (
    SELECT
      ss.ss_ticket_number      AS order_id,
      ss.ss_net_paid           AS net_paid,
      i.i_item_id              AS i_item_id,
      t.t_hour                 AS t_hour,
      ARRAY[ss.ss_quantity, ss.ss_ext_sales_price] AS qty_price_arr
    FROM store_sales ss
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
  ),
  sub2_unnest AS (
    SELECT
      order_id,
      net_paid,
      i_item_id,
      t_hour,
      u.value AS array_value
    FROM sub2
    CROSS JOIN UNNEST(qty_price_arr) AS u(value)
  ),
  combined AS (
    SELECT order_id, net_paid, i_item_id, t_hour, array_value FROM sub1_unnest
    UNION ALL
    SELECT order_id, net_paid, i_item_id, t_hour, array_value FROM sub2_unnest
  ),
  final AS (
    SELECT
      order_id,
      net_paid,
      i_item_id,
      t_hour,
      array_value,
      LAG(array_value) OVER (PARTITION BY order_id ORDER BY array_value)               AS prev_array_value,
      SUM(array_value) OVER (PARTITION BY order_id ORDER BY array_value
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM combined
    WHERE order_id NOT IN (
      SELECT cs_order_number FROM catalog_sales WHERE cs_net_paid > 10000
    )
  )
SELECT *
FROM final
ORDER BY order_id
LIMIT 100
