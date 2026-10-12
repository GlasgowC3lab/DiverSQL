WITH store_sales_filtered AS (
    SELECT
        ca.ca_state AS state,
        CAST(substr(CAST(ss.ss_sold_date_sk AS varchar), 5, 2) AS integer) AS month,
        'store' AS channel,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND ca.ca_location_type IN ('condo', 'apartment')
), web_sales_filtered AS (
    SELECT
        ca.ca_state AS state,
        CAST(substr(CAST(ws.ws_sold_date_sk AS varchar), 5, 2) AS integer) AS month,
        'web' AS channel,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'product'
      AND ca.ca_location_type IN ('condo', 'apartment')
), combined AS (
    SELECT * FROM store_sales_filtered
    UNION ALL
    SELECT * FROM web_sales_filtered
), aggregated AS (
    SELECT
        state,
        month,
        channel,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        AVG(discount) AS avg_discount,
        SUM(quantity) AS total_quantity
    FROM combined
    GROUP BY state, month, channel
)
SELECT
    state,
    month,
    channel,
    total_net_paid,
    total_net_profit,
    avg_discount,
    total_quantity,
    RANK() OVER (PARTITION BY month ORDER BY total_net_paid DESC) AS state_month_rank
FROM aggregated
ORDER BY month, total_net_paid DESC, state
