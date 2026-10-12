WITH sales_base AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       ws.ws_quantity,
       ws.ws_net_profit,
       ws.ws_sold_time_sk,
       ws.ws_ship_mode_sk,
       ws.ws_warehouse_sk,
       ws.ws_bill_customer_sk,
       ws.ws_ship_customer_sk,
       ws.ws_web_page_sk,
       t.t_hour,
       sm.sm_type,
       w.w_state,
       wp.wp_type,
       c_bill.c_customer_id   AS bill_customer_id,
       c_ship.c_customer_id   AS ship_customer_id,
       ca.ca_address_id       AS bill_address_id
   FROM web_sales ws
   RIGHT OUTER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim t      ON ws.ws_sold_time_sk   = t.t_time_sk
   JOIN warehouse w     ON ws.ws_warehouse_sk   = w.w_warehouse_sk
   JOIN web_page wp    ON ws.ws_web_page_sk    = wp.wp_web_page_sk
   JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
   LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk AND cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_returns sr   ON sr.sr_return_time_sk = t.t_time_sk
   LEFT JOIN web_returns wr     ON wr.wr_returned_time_sk = t.t_time_sk AND wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    order_number,
    sold_date_sk,
    hour,
    ship_mode_type,
    warehouse_state,
    page_type,
    quantity,
    net_profit,
    profit_rank,
    total_return_amount_for_day
FROM (
    SELECT
        sb.ws_order_number                         AS order_number,
        sb.ws_sold_date_sk                         AS sold_date_sk,
        sb.t_hour                                  AS hour,
        sb.sm_type                                 AS ship_mode_type,
        sb.w_state                                 AS warehouse_state,
        sb.wp_type                                 AS page_type,
        sb.ws_quantity                             AS quantity,
        sb.ws_net_profit                           AS net_profit,
        RANK() OVER (PARTITION BY sb.ws_warehouse_sk ORDER BY sb.ws_net_profit DESC) AS profit_rank,
        (SELECT SUM(cr_inner.cr_return_amount)
         FROM catalog_returns cr_inner
         WHERE cr_inner.cr_returned_date_sk = sb.ws_sold_date_sk) AS total_return_amount_for_day
    FROM sales_base sb
    WHERE sb.t_hour BETWEEN 9 AND 17
      AND sb.sm_type = 'AIR'
      AND sb.w_state = 'CA'
      AND sb.wp_type = 'CONTENT'
      AND sb.ws_quantity > 5
) AS q1
UNION DISTINCT
SELECT
    order_number,
    sold_date_sk,
    hour,
    ship_mode_type,
    warehouse_state,
    page_type,
    quantity,
    net_profit,
    profit_rank,
    total_return_amount_for_day
FROM (
    SELECT
        sb.ws_order_number                         AS order_number,
        sb.ws_sold_date_sk                         AS sold_date_sk,
        sb.t_hour                                  AS hour,
        sb.sm_type                                 AS ship_mode_type,
        sb.w_state                                 AS warehouse_state,
        sb.wp_type                                 AS page_type,
        sb.ws_quantity                             AS quantity,
        sb.ws_net_profit                           AS net_profit,
        RANK() OVER (PARTITION BY sb.ws_warehouse_sk ORDER BY sb.ws_net_profit DESC) AS profit_rank,
        (SELECT SUM(cr_inner.cr_return_amount)
         FROM catalog_returns cr_inner
         WHERE cr_inner.cr_returned_date_sk = sb.ws_sold_date_sk) AS total_return_amount_for_day
    FROM sales_base sb
    WHERE sb.t_hour BETWEEN 18 AND 23
      AND sb.sm_type = 'GROUND'
      AND sb.w_state = 'NY'
      AND sb.wp_type = 'NAVIGATION'
      AND sb.ws_quantity > 10
) AS q2
ORDER BY profit_rank, total_return_amount_for_day DESC
LIMIT 100
