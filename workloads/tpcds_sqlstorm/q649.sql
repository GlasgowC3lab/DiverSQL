WITH store_data AS (
    SELECT
        d.d_year AS year,
        s.s_state AS state,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
),
web_data AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
catalog_data AS (
    SELECT
        d.d_year AS year,
        cc.cc_state AS state,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
union_data AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
    UNION ALL
    SELECT * FROM catalog_data
)
SELECT
    year,
    state,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    COUNT(DISTINCT cust_sk) AS distinct_customers
FROM union_data
GROUP BY year, state
ORDER BY year, state
