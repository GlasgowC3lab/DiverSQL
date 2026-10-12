WITH returns_summary AS (
    SELECT
        wr.wr_web_page_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk, wr.wr_returned_date_sk
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_closed.d_date AS store_closed_date,
    wp.wp_url,
    wp.wp_type,
    d_creation.d_date AS page_creation_date,
    d_access.d_date AS page_access_date,
    rs.total_return_amt,
    rs.total_return_qty,
    rs.return_cnt,
    d_return.d_date AS return_date,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY rs.total_return_amt DESC) AS dept_return_rank
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN returns_summary rs ON rs.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_return ON rs.wr_returned_date_sk = d_return.d_date_sk
WHERE cp.cp_type = 'Catalog'
ORDER BY cp.cp_department, dept_return_rank
LIMIT 100
