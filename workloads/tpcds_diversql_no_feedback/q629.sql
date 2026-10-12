/*
Goal: Calculate the average sales per state for items in the 'accessories' category, classifying the average as above or below a threshold, combine two slightly different aggregations via UNION, enrich the result with the most frequent email domain count per state (using UNNEST on the email address), and return the top 100 states ordered by average sales.
*/
WITH base_sales AS (
    SELECT
        ca.ca_state,
        i.i_class,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        c.c_email_address
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
      AND i.i_category = 'accessories'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs.cs_quantity > 1
),
agg_sales AS (
    SELECT
        ca_state,
        i_class,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_qty
    FROM base_sales
    GROUP BY ca_state, i_class
),
state_avg AS (
    SELECT
        ca_state,
        AVG(total_sales) AS avg_sales,
        COUNT(*) AS class_cnt,
        CASE WHEN AVG(total_sales) > 5000 THEN 'AboveAvg' ELSE 'BelowAvg' END AS avg_sales_level
    FROM agg_sales
    GROUP BY ca_state
),
state_avg_alt AS (
    SELECT
        ca_state,
        AVG(total_sales) * 0.9 AS avg_sales,
        COUNT(*) AS class_cnt,
        CASE WHEN AVG(total_sales) * 0.9 > 5000 THEN 'AboveAvg' ELSE 'BelowAvg' END AS avg_sales_level
    FROM agg_sales
    WHERE i_class <> 'infants'
    GROUP BY ca_state
),
union_state AS (
    SELECT ca_state, avg_sales, class_cnt, avg_sales_level FROM state_avg
    UNION DISTINCT
    SELECT ca_state, avg_sales, class_cnt, avg_sales_level FROM state_avg_alt
),
email_domains AS (
    SELECT
        ca_state,
        email_part AS email_domain,
        COUNT(*) AS domain_cnt
    FROM (
        SELECT
            ca.ca_state,
            part AS email_part
        FROM tpcds.catalog_sales cs
        JOIN tpcds.customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        CROSS JOIN UNNEST(split(c.c_email_address, '@')) AS t(part)
    )
    WHERE email_part LIKE '%.%'
    GROUP BY ca_state, email_part
),
top_domain AS (
    SELECT
        ca_state,
        MAX(domain_cnt) AS top_domain_cnt
    FROM email_domains
    GROUP BY ca_state
)
SELECT
    u.ca_state,
    u.avg_sales,
    u.avg_sales_level,
    td.top_domain_cnt
FROM union_state u
JOIN top_domain td
    ON u.ca_state = td.ca_state
ORDER BY u.avg_sales DESC
LIMIT 100
