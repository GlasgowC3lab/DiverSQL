WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_country,
        ca.ca_state AS ca_state,
        ca.ca_city,
        cd.cd_gender,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_wholesale_cost,
        ss.ss_sold_date_sk,
        ss.ss_store_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_country = 'United States'
      AND ss.ss_wholesale_cost > 30
      AND cd.cd_gender = 'F'
      AND ca.ca_state = 'CA'
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.ca_city,
    b.cd_gender,
    b.ss_sales_price,
    b.ss_quantity,
    b.ss_net_paid,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_id ORDER BY b.ss_sales_price DESC) AS sales_rank,
    SUM(b.ss_net_paid) OVER (PARTITION BY b.s_store_id ORDER BY b.ss_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
    LAG(b.ss_sales_price) OVER (PARTITION BY b.s_store_id ORDER BY b.ss_sold_date_sk) AS prev_sales_price,
    (SELECT COUNT(*)
     FROM store_sales ss2
     WHERE ss2.ss_store_sk = b.ss_store_sk) AS total_transactions_for_store
FROM base b
ORDER BY b.s_store_id, sales_rank
LIMIT 100
