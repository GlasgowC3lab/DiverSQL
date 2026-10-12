SELECT
    d.d_year,
    s.s_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    wp.wp_type,
    CASE WHEN wp.wp_image_count > 0 THEN 'HasImage' ELSE 'NoImage' END AS image_flag,
    COUNT(*) AS returns_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee + cr.cr_store_credit) AS total_return_cost,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_reversed_charge) AS total_reversed_charge,
    CASE 
        WHEN SUM(cr.cr_return_amount) > 0 
        THEN SUM(cr.cr_net_loss) / SUM(cr.cr_return_amount) 
        ELSE NULL 
    END AS net_loss_ratio
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY
    d.d_year,
    s.s_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    wp.wp_type,
    CASE WHEN wp.wp_image_count > 0 THEN 'HasImage' ELSE 'NoImage' END
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
