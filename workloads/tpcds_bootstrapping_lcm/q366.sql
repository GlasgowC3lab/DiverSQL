SELECT
    r.r_reason_desc,
    d.d_year,
    d.d_month_seq,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wp_creation.wp_web_page_id) AS created_pages_on_return_date,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS accessed_pages_on_return_date
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp_creation
    ON wp_creation.wp_creation_date_sk = d.d_date_sk
JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND r.r_reason_desc IS NOT NULL
GROUP BY
    r.r_reason_desc,
    d.d_year,
    d.d_month_seq,
    s.s_state
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
