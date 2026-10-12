WITH sales_agg AS (
    SELECT 
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        start_d.d_year AS start_year,
        end_d.d_year AS end_year,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT st.s_store_id) AS num_stores,
        SUM(CASE WHEN store_closed_d.d_date_sk IS NOT NULL THEN st.s_floor_space ELSE 0 END) AS total_floor_space_closed,
        SUM(CASE WHEN store_closed_d.d_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS stores_closed_in_range
    FROM catalog_page cp
    JOIN date_dim start_d ON cp.cp_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON cp.cp_end_date_sk = end_d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    JOIN date_dim sales_d ON ss.ss_sold_date_sk = sales_d.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN date_dim store_closed_d ON st.s_closed_date_sk = store_closed_d.d_date_sk
    GROUP BY cp.cp_catalog_page_id, cp.cp_department, cp.cp_type, start_d.d_year, end_d.d_year
),
returns_agg AS (
    SELECT 
        cp.cp_catalog_page_id,
        COUNT(DISTINCT wr.wr_order_number) AS num_return_transactions,
        SUM(wr.wr_return_amt) AS total_returns
    FROM catalog_page cp
    JOIN web_returns wr
        ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    JOIN date_dim returns_d ON wr.wr_returned_date_sk = returns_d.d_date_sk
    GROUP BY cp.cp_catalog_page_id
)
SELECT 
    s.cp_catalog_page_id,
    s.cp_department,
    s.cp_type,
    s.start_year,
    s.end_year,
    s.num_sales_transactions,
    s.total_sales,
    s.total_discount,
    s.num_stores,
    s.stores_closed_in_range,
    s.total_floor_space_closed,
    COALESCE(r.num_return_transactions, 0) AS num_return_transactions,
    COALESCE(r.total_returns, 0) AS total_returns,
    (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
FROM sales_agg s
LEFT JOIN returns_agg r ON s.cp_catalog_page_id = r.cp_catalog_page_id
ORDER BY net_sales DESC
LIMIT 100
