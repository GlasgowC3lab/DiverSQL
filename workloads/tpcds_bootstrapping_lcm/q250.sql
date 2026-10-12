SELECT
    d_ret.d_year,
    d_ret.d_quarter_seq,
    s.s_state,
    CASE
        WHEN i.inv_quantity_on_hand < 100 THEN 'Low'
        WHEN i.inv_quantity_on_hand BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END AS inventory_bucket,
    CASE
        WHEN wp.wp_type = 'product' THEN 'Product'
        WHEN wp.wp_type = 'category' THEN 'Category'
        ELSE 'Other'
    END AS page_type,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(CASE WHEN d_ret.d_holiday = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS holiday_return_amount,
    SUM(CASE WHEN d_ret.d_weekend = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS weekend_return_amount,
    SUM(CASE WHEN d_access.d_weekend = 'Y' THEN wp.wp_char_count ELSE 0 END) AS weekend_char_count,
    SUM(CASE WHEN d_cl.d_year = d_ret.d_year - 1 THEN sr.sr_return_amt ELSE 0 END) AS prior_year_closed_return_amount
FROM
    date_dim d_ret
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_cl ON s.s_closed_date_sk = d_cl.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE
    d_ret.d_year BETWEEN 2020 AND 2022
    AND s.s_state IS NOT NULL
    AND i.inv_quantity_on_hand IS NOT NULL
GROUP BY
    1, 2, 3, 4, 5
HAVING
    SUM(sr.sr_return_amt) > 500
ORDER BY
    d_ret.d_year,
    d_ret.d_quarter_seq,
    s.s_state,
    inventory_bucket,
    page_type
LIMIT 100
