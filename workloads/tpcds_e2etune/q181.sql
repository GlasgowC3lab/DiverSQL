WITH category_sales AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        ca.ca_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = 7
      AND ca.ca_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ss.ss_quantity > 0
    GROUP BY i.i_category, cd.cd_gender, ca.ca_state
    HAVING SUM(ss.ss_ext_sales_price) > 1000
)
SELECT
    i_category,
    cd_gender,
    ca_state,
    total_sales,
    total_profit,
    avg_discount,
    distinct_customers,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM category_sales
ORDER BY total_sales DESC
LIMIT 50
