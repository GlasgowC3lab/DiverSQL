WITH agg AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_return.d_year AS return_year,
        d_return.d_quarter_name AS return_quarter,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        MIN(d_return.d_date) AS first_return_date,
        MAX(d_return.d_date) AS last_return_date,
        MAX(d_wp_creation.d_year) AS max_page_creation_year,
        MIN(d_wp_access.d_year) AS min_page_access_year
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    GROUP BY 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_return.d_year,
        d_return.d_quarter_name
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT 
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    return_year,
    return_quarter,
    distinct_pages,
    total_return_amt,
    total_net_loss,
    avg_return_qty,
    first_return_date,
    last_return_date,
    max_page_creation_year,
    min_page_access_year,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_amt DESC) AS store_rank
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
