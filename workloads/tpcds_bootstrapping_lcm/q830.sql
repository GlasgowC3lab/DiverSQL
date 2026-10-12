SELECT
    c_ref.c_birth_country AS customer_birth_country,
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    s.s_state AS store_state,
    wp.wp_type AS web_page_type,
    CASE
        WHEN date_diff('day', d_first_sales.d_date, d_ret.d_date) < 30 THEN '0-30 days'
        WHEN date_diff('day', d_first_sales.d_date, d_ret.d_date) BETWEEN 30 AND 89 THEN '30-89 days'
        ELSE '90+ days'
    END AS sales_age_bucket,
    COUNT(*) AS return_count,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_amount) AS total_return_amount,
    MAX(cr.cr_fee) AS max_fee,
    MIN(cr.cr_fee) AS min_fee,
    SUM(cr.cr_store_credit) AS total_store_credit,
    (SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0)) AS net_loss_ratio,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN 1 ELSE 0 END) AS positive_loss_count
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_ret.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_first_sales
    ON c_ret.c_first_sales_date_sk = d_first_sales.d_date_sk
GROUP BY
    c_ref.c_birth_country,
    d_ret.d_year,
    d_ret.d_moy,
    s.s_state,
    wp.wp_type,
    CASE
        WHEN date_diff('day', d_first_sales.d_date, d_ret.d_date) < 30 THEN '0-30 days'
        WHEN date_diff('day', d_first_sales.d_date, d_ret.d_date) BETWEEN 30 AND 89 THEN '30-89 days'
        ELSE '90+ days'
    END
ORDER BY total_net_loss DESC
LIMIT 100
