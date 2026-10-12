SELECT
    d_ret.d_year AS return_year,
    s.s_state,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space BETWEEN 20000 AND 50000 THEN 'Medium Store'
        ELSE 'Small Store'
    END AS store_size_category,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wp.wp_type = 'Content' THEN 1 ELSE 0 END) AS content_page_returns,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_page_returns,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(SUM(s.s_floor_space), 0), 4) AS return_per_sqft,
    MIN(d_cre.d_date) AS page_creation_min_date,
    MAX(d_acc.d_date) AS page_access_max_date
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_cre ON wp.wp_creation_date_sk = d_cre.d_date_sk
JOIN date_dim d_acc ON wp.wp_access_date_sk = d_acc.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2020
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY
    d_ret.d_year,
    s.s_state,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space BETWEEN 20000 AND 50000 THEN 'Medium Store'
        ELSE 'Small Store'
    END
HAVING COUNT(*) > 10
ORDER BY d_ret.d_year DESC, total_return_amount DESC
LIMIT 100
