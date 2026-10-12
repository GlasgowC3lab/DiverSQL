WITH filtered_customers AS (
        SELECT DISTINCT
            c_customer_sk,
            CONCAT(c_first_name, ' ', c_last_name) AS full_name,
            c_email_address
        FROM customer
        WHERE regexp_like(c_email_address, '^.*@example\\.com$')
          AND c_preferred_cust_flag = 'Y'
    ),
    sales_agg AS (
        SELECT
            fc.c_customer_sk,
            fc.full_name,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(DISTINCT cs.cs_order_number) AS orders
        FROM filtered_customers fc
        JOIN catalog_sales cs
          ON cs.cs_bill_customer_sk = fc.c_customer_sk
        JOIN call_center cc
          ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE cc.cc_name LIKE 'North%'
        GROUP BY fc.c_customer_sk, fc.full_name
        UNION DISTINCT
        SELECT
            fc.c_customer_sk,
            fc.full_name,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(DISTINCT ws.ws_order_number) AS orders
        FROM filtered_customers fc
        JOIN web_sales ws
          ON ws.ws_bill_customer_sk = fc.c_customer_sk
        JOIN warehouse w
          ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_city LIKE '%York%'
        GROUP BY fc.c_customer_sk, fc.full_name
    ),
    customers_no_returns AS (
        SELECT c_customer_sk FROM sales_agg
        EXCEPT
        SELECT sr_customer_sk FROM store_returns
    )
SELECT
    sa.c_customer_sk,
    sa.full_name,
    sa.total_profit,
    sa.orders
FROM sales_agg sa
JOIN customers_no_returns cnr
  ON sa.c_customer_sk = cnr.c_customer_sk
ORDER BY sa.total_profit DESC
LIMIT 100
