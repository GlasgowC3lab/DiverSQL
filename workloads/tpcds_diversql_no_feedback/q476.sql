WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        sm.sm_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    FULL OUTER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        c.c_birth_year = 1975
        AND ca.ca_gmt_offset = -5.00
        AND sr.sr_store_credit > 100
        AND ws.ws_ext_ship_cost BETWEEN 10 AND 100
        AND sm.sm_code = 'AIR'
        AND ss.ss_customer_sk IN (
            SELECT c_customer_sk
            FROM customer
            WHERE c_preferred_cust_flag = 'Y'
        )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        sm.sm_type
    HAVING
        SUM(ss.ss_ext_sales_price) > 1000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_state,
    sm_type,
    total_sales,
    total_returns,
    num_transactions,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS state_sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
