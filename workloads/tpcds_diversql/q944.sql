WITH computed_numbers AS (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            ss.ss_ext_sales_price AS ss_sales,
            ss.ss_net_profit AS ss_profit,
            d.d_year,
            t.t_meal_time,
            c.c_customer_sk,
            c.c_birth_month,
            ca.ca_state,
            ca.ca_zip,
            CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON cs.cs_sold_time_sk = t.t_time_sk
        FULL OUTER JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
           AND ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk
        WHERE c.c_birth_month = 9
          AND ca.ca_zip = '39145'
          AND t.t_meal_time = 'lunch'
          AND d.d_date = DATE '2001-01-01'
          AND EXISTS (
                SELECT 1
                FROM catalog_returns cr2
                WHERE cr2.cr_order_number = cs.cs_order_number
                  AND cr2.cr_return_amount > 0
          )
    )
SELECT
    d_year,
    t_meal_time,
    ca_state,
    profit_flag,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss_sales) AS total_store_sales,
    AVG(CASE WHEN profit_flag = 'POS' THEN cs_net_profit END) AS avg_positive_profit
FROM base
CROSS JOIN (SELECT * FROM computed_numbers) cn
GROUP BY d_year, t_meal_time, ca_state, profit_flag
ORDER BY total_catalog_sales DESC
LIMIT 100
