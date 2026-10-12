WITH agg AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        wp.wp_type,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(wp.wp_link_count) AS total_page_links,
        SUM(cr.cr_return_amt_inc_tax) / NULLIF(SUM(wp.wp_link_count), 0) AS return_per_link
    FROM catalog_returns cr
    JOIN web_page wp
        ON cr.cr_returned_date_sk = wp.wp_access_date_sk
    WHERE cr.cr_return_amt_inc_tax > 100
      AND cr.cr_reason_sk IN (51, 62)
      AND wp.wp_type IS NOT NULL
    GROUP BY cr.cr_returned_date_sk, wp.wp_type
    HAVING SUM(cr.cr_return_amt_inc_tax) > 500
)
SELECT
    return_date_sk,
    wp_type,
    distinct_customers,
    total_return_amount,
    avg_return_amount,
    total_return_quantity,
    total_page_links,
    return_per_link,
    RANK() OVER (PARTITION BY wp_type ORDER BY total_return_amount DESC) AS type_rank_by_return
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
