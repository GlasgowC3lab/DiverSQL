WITH sales_summary AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        d_sales.d_year,
        d_sales.d_quarter_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(cp.creation_count) AS total_pages_created_on_sales_date,
        SUM(ap.access_count) AS total_pages_accessed_on_sales_date,
        MAX(d_closed.d_date) AS store_closed_date
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN (
        SELECT wp.wp_creation_date_sk AS date_sk, COUNT(*) AS creation_count
        FROM web_page wp
        GROUP BY wp.wp_creation_date_sk
    ) cp
        ON cp.date_sk = d_sales.d_date_sk
    LEFT JOIN (
        SELECT wp.wp_access_date_sk AS date_sk, COUNT(*) AS access_count
        FROM web_page wp
        GROUP BY wp.wp_access_date_sk
    ) ap
        ON ap.date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year BETWEEN 2021 AND 2022
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        d_sales.d_year,
        d_sales.d_quarter_name
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    s_store_name,
    s_state,
    i_category,
    i_brand,
    d_year,
    d_quarter_name,
    total_sales,
    total_net_profit,
    distinct_tickets,
    total_pages_created_on_sales_date,
    total_pages_accessed_on_sales_date,
    store_closed_date,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS yearly_sales_rank
FROM sales_summary
ORDER BY total_sales DESC
LIMIT 100
