WITH daily_stats AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT s.s_store_id) AS stores_closed,
        SUM(s.s_floor_space) AS total_floor_space,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
        COUNT(DISTINCT wp.wp_type) AS page_types
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_date, d.d_year, d.d_month_seq, i.i_category, i.i_brand
)
SELECT
    ds.d_date,
    ds.d_year,
    ds.d_month_seq,
    ds.i_category,
    ds.i_brand,
    ds.total_return_amount,
    ds.total_return_quantity,
    ds.avg_wholesale_cost,
    ds.stores_closed,
    ds.total_floor_space,
    ds.pages_created,
    ds.page_types,
    ds.total_return_amount / NULLIF(ds.stores_closed, 0) AS avg_return_per_store,
    ROW_NUMBER() OVER (ORDER BY ds.total_return_amount DESC) AS return_amount_rank
FROM daily_stats ds
ORDER BY ds.total_return_amount DESC
LIMIT 100
