SELECT
    d.d_year,
    d.d_month_seq,
    s.s_market_desc,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS returns_count,
    MIN(wp.wp_url) AS earliest_created_page,
    COUNT(DISTINCT wp_acc.wp_web_page_id) AS distinct_access_pages
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_page wp_acc
    ON wp_acc.wp_access_date_sk = d.d_date_sk
WHERE cd_ref.cd_gender = 'F'
  AND cd_ret.cd_gender = 'F'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_market_desc,
    cd_ref.cd_gender,
    cd_ret.cd_gender
ORDER BY total_net_loss DESC
LIMIT 100
