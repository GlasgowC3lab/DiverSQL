SELECT
    d.d_year,
    d.d_moy AS month,
    s.s_division_id,
    wp_c.wp_type,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount_sum,
    SUM(wp_c.wp_image_count) AS total_image_count,
    SUM(wp_a.wp_link_count) AS total_link_count,
    SUM(CASE WHEN s.s_tax_percentage > 5 THEN s.s_tax_percentage * cr.cr_return_amount ELSE 0 END) AS tax_adjusted_return_sum
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp_c
    ON wp_c.wp_creation_date_sk = d.d_date_sk
JOIN web_page wp_a
    ON wp_a.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2020
GROUP BY
    d.d_year,
    d.d_moy,
    s.s_division_id,
    wp_c.wp_type,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
