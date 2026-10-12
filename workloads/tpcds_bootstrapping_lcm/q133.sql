WITH sales_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        d_start.d_year AS start_year,
        d_start.d_month_seq AS start_month_seq,
        d_end.d_year AS end_year,
        d_end.d_month_seq AS end_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        MIN(wp.wp_url) AS sample_url,
        d_store.d_date AS store_closed_date,
        d_web_access.d_date AS web_page_access_date
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_start.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
    JOIN date_dim d_web_access ON wp.wp_access_date_sk = d_web_access.d_date_sk
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        d_start.d_year,
        d_start.d_month_seq,
        d_end.d_year,
        d_end.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_store.d_date,
        d_web_access.d_date
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    start_year,
    start_month_seq,
    end_year,
    end_month_seq,
    s_store_id,
    s_city,
    s_state,
    tickets_sold,
    total_ext_sales,
    total_net_profit,
    avg_sales_price,
    distinct_web_pages,
    sample_url,
    store_closed_date,
    web_page_access_date,
    ROW_NUMBER() OVER (ORDER BY total_ext_sales DESC) AS rank
FROM sales_agg
ORDER BY rank
LIMIT 100
