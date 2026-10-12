WITH store_sales_agg AS (
    SELECT
        c.c_customer_sk AS customer_key,
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(ss.ss_net_paid_inc_tax) AS total_paid
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND c.c_customer_sk NOT IN (SELECT DISTINCT sr_customer_sk FROM tpcds.store_returns)
    GROUP BY GROUPING SETS (
        (c.c_customer_sk, d.d_year, ca.ca_state),
        (c.c_customer_sk, d.d_year),
        (c.c_customer_sk, ca.ca_state),
        (c.c_customer_sk)
    )
),
web_sales_agg AS (
    SELECT
        c.c_customer_sk AS customer_key,
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND c.c_customer_sk NOT IN (SELECT DISTINCT wr_refunded_customer_sk FROM tpcds.web_returns)
    GROUP BY GROUPING SETS (
        (c.c_customer_sk, d.d_year, ca.ca_state),
        (c.c_customer_sk, d.d_year),
        (c.c_customer_sk, ca.ca_state),
        (c.c_customer_sk)
    )
)
SELECT *
FROM store_sales_agg
INTERSECT
SELECT *
FROM web_sales_agg
ORDER BY total_paid DESC
LIMIT 100
