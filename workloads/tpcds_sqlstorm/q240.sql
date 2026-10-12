WITH
sales_union AS (
    SELECT ss_customer_sk AS customer_sk,
           ss_item_sk AS item_sk,
           ss_sold_date_sk AS sold_date_sk,
           ss_quantity AS quantity,
           ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_item_sk AS item_sk,
           ws_sold_date_sk AS sold_date_sk,
           ws_quantity AS quantity,
           ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_item_sk AS item_sk,
           cs_sold_date_sk AS sold_date_sk,
           cs_quantity AS quantity,
           cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales
),
sales_agg AS (
    SELECT
        customer_sk,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit,
        COUNT(DISTINCT item_sk) AS distinct_items_sold,
        MIN(sold_date_sk) AS first_sold_date_sk,
        MAX(sold_date_sk) AS last_sold_date_sk
    FROM sales_union
    WHERE sold_date_sk IS NOT NULL
    GROUP BY customer_sk
),
returns_union AS (
    SELECT sr_customer_sk AS customer_sk,
           sr_item_sk AS item_sk,
           sr_returned_date_sk AS returned_date_sk,
           sr_return_quantity AS quantity,
           sr_net_loss AS net_loss,
           'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT wr_refunded_customer_sk AS customer_sk,
           wr_item_sk AS item_sk,
           wr_returned_date_sk AS returned_date_sk,
           wr_return_quantity AS quantity,
           wr_net_loss AS net_loss,
           'web' AS channel
    FROM web_returns
    UNION ALL
    SELECT cr_refunded_customer_sk AS customer_sk,
           cr_item_sk AS item_sk,
           cr_returned_date_sk AS returned_date_sk,
           cr_return_quantity AS quantity,
           cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns
),
returns_agg AS (
    SELECT
        customer_sk,
        SUM(quantity) AS total_return_quantity,
        SUM(net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM returns_union
    GROUP BY customer_sk
),
sales_returns_combined AS (
    SELECT
        COALESCE(sa.customer_sk, ra.customer_sk) AS customer_sk,
        sa.total_quantity,
        sa.total_net_profit,
        ra.total_return_quantity,
        ra.total_return_loss
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra ON sa.customer_sk = ra.customer_sk
),
category_avg_profit AS (
    SELECT i.i_category,
           AVG(su.net_profit) AS avg_category_profit
    FROM sales_union su
    JOIN item i ON su.item_sk = i.i_item_sk
    GROUP BY i.i_category
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_dates AS (
    SELECT
        sa.customer_sk,
        d_first.d_date AS first_purchase_date,
        d_last.d_date AS last_purchase_date
    FROM sales_agg sa
    LEFT JOIN date_dim d_first ON d_first.d_date_sk = sa.first_sold_date_sk
    LEFT JOIN date_dim d_last ON d_last.d_date_sk = sa.last_sold_date_sk
)
SELECT
    cd.c_customer_sk,
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.preferred_flag,
    COALESCE(src.total_quantity, 0) AS total_quantity,
    COALESCE(src.total_net_profit, 0) AS total_net_profit,
    COALESCE(src.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(src.total_return_loss, 0) AS total_return_loss,
    COALESCE(src.total_net_profit, 0) - COALESCE(src.total_return_loss, 0) AS net_profit_after_returns,
    CASE WHEN COALESCE(src.total_quantity, 0) = 0 THEN NULL
         ELSE (COALESCE(src.total_net_profit, 0) - COALESCE(src.total_return_loss, 0)) / COALESCE(src.total_quantity, 1)
    END AS profit_per_item,
    (SELECT AVG(cap.avg_category_profit)
     FROM sales_union su2
     JOIN item i2 ON su2.item_sk = i2.i_item_sk
     JOIN category_avg_profit cap ON i2.i_category = cap.i_category
     WHERE su2.customer_sk = cd.c_customer_sk) AS avg_category_profit_for_customer,
    RANK() OVER (PARTITION BY cd.ca_city ORDER BY (COALESCE(src.total_net_profit, 0) - COALESCE(src.total_return_loss, 0)) DESC) AS city_profit_rank,
    sd.first_purchase_date,
    sd.last_purchase_date,
    CASE WHEN (COALESCE(src.total_net_profit, 0) - COALESCE(src.total_return_loss, 0)) > 10000 THEN 'YES' ELSE 'NO' END AS high_value_customer
FROM customer_details cd
LEFT JOIN sales_returns_combined src ON cd.c_customer_sk = src.customer_sk
LEFT JOIN sales_dates sd ON cd.c_customer_sk = sd.customer_sk
WHERE COALESCE(src.total_net_profit, 0) - COALESCE(src.total_return_loss, 0) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
