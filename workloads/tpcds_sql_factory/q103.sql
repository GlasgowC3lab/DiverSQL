WITH page_returns AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_image_count,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_transactions
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
    GROUP BY wp.wp_web_page_id, wp.wp_url, wp.wp_type, wp.wp_char_count, wp.wp_image_count
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT
    pr.wp_web_page_id,
    pr.wp_url,
    pr.wp_type,
    pr.wp_char_count,
    pr.wp_image_count,
    pr.total_return_amount,
    pr.return_transactions,
    CASE 
        WHEN pr.wp_type = 'PRODUCT' THEN 'PRODUCT_PAGE'
        WHEN pr.wp_type = 'CATEGORY' THEN 'CATEGORY_PAGE'
        ELSE 'OTHER_PAGE'
    END AS page_category,
    PERCENT_RANK() OVER (ORDER BY pr.total_return_amount DESC) AS return_amount_percentile
FROM page_returns pr
ORDER BY pr.total_return_amount DESC
LIMIT 20
