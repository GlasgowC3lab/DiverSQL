WITH store_agg AS (
    SELECT
        'store' AS source,
        ca_state AS state,
        SUM(ss_net_paid_inc_tax) AS total_net_paid,
        CASE WHEN SUM(ss_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS payment_category
    FROM store_sales
    JOIN customer_address
        ON store_sales.ss_addr_sk = customer_address.ca_address_sk
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451175
    GROUP BY ca_state
),
web_agg AS (
    SELECT
        'web' AS source,
        ca_state AS state,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        CASE WHEN SUM(ws_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS payment_category
    FROM web_sales
    JOIN ship_mode
        ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    JOIN customer_address
        ON web_sales.ws_ship_addr_sk = customer_address.ca_address_sk
    WHERE ws_ship_mode_sk IS NOT NULL
      AND ws_sold_date_sk BETWEEN 2450815 AND 2451175
    GROUP BY ca_state
)
SELECT source, state, total_net_paid, payment_category
FROM store_agg
UNION ALL
SELECT source, state, total_net_paid, payment_category
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
