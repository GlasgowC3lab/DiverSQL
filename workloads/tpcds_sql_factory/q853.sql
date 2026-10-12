WITH all_sales AS (
    SELECT
        cs_order_number AS order_number,
        cs_sold_date_sk AS sold_date_sk,
        cs_sold_time_sk AS sold_time_sk,
        cs_net_paid_inc_tax AS net_paid,
        cs_bill_customer_sk AS customer_sk,
        cs_ship_addr_sk AS ship_addr_sk,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_net_paid_inc_tax,
        ws_bill_customer_sk,
        ws_ship_addr_sk,
        'web' AS channel
    FROM web_sales
),
ordered_sales AS (
    SELECT
        *,
        LAG(net_paid) OVER (PARTITION BY customer_sk ORDER BY sold_date_sk, sold_time_sk, order_number) AS prev_net_paid
    FROM all_sales
)
SELECT
    os.customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    os.order_number,
    os.sold_date_sk,
    os.channel,
    os.net_paid,
    os.prev_net_paid,
    CASE
        WHEN os.prev_net_paid IS NULL THEN 'First Purchase'
        WHEN os.net_paid > os.prev_net_paid THEN 'Increasing'
        ELSE 'Decreasing/Flat'
    END AS trend_indicator,
    ROW_NUMBER() OVER (PARTITION BY os.customer_sk ORDER BY os.sold_date_sk, os.sold_time_sk) AS purchase_seq
FROM ordered_sales os
JOIN customer c ON os.customer_sk = c.c_customer_sk
JOIN customer_address ca ON os.ship_addr_sk = ca.ca_address_sk
WHERE os.net_paid IS NOT NULL
ORDER BY os.customer_sk, os.sold_date_sk, os.sold_time_sk
LIMIT 200
