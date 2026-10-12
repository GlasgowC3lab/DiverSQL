WITH sales_with_details AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ti.t_hour,
        ti.t_meal_time,
        it.i_item_id,
        it.i_class,
        it.i_brand,
        it.i_category,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_state AS ship_state,
        pr.p_promo_name,
        pr.p_discount_active,
        pr.p_purpose,
        RANK() OVER (PARTITION BY it.i_brand ORDER BY ws.ws_net_paid DESC) AS brand_net_paid_rank,
        LAG(ws.ws_net_paid, 1) OVER (PARTITION BY it.i_category ORDER BY ws.ws_sold_date_sk) AS prev_category_net_paid,
        SUM(ws.ws_net_paid) OVER (PARTITION BY it.i_brand ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_brand_net_paid
    FROM web_sales ws
    JOIN time_dim ti
        ON ws.ws_sold_time_sk = ti.t_time_sk
    JOIN item it
        ON ws.ws_item_sk = it.i_item_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN promotion pr
        ON ws.ws_promo_sk = pr.p_promo_sk
    WHERE ti.t_hour BETWEEN 9 AND 17
      AND it.i_class = 'sports-apparel'
      AND pr.p_discount_active = 'Y'
      AND ws.ws_net_paid > 1000
      AND ws.ws_net_paid > (SELECT avg(ws2.ws_net_paid) FROM web_sales ws2)
)
SELECT
    ws_order_number,
    ws_sold_date_sk,
    i_item_id,
    i_class,
    i_brand,
    bill_city,
    ship_state,
    p_promo_name,
    ws_quantity,
    ws_net_paid,
    brand_net_paid_rank,
    prev_category_net_paid,
    running_brand_net_paid
FROM sales_with_details
ORDER BY ws_net_paid DESC
LIMIT 100
