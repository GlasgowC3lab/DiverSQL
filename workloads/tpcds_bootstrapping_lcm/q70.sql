SELECT
    d_cr.d_year AS year,
    CASE
        WHEN d_cr.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    s.s_state,
    s.s_city,
    cd_refund_cr.cd_gender AS refunded_gender,
    cd_return_cr.cd_gender AS returning_gender,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    COUNT(*) AS total_rows
FROM catalog_returns AS cr
JOIN date_dim AS d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN customer_demographics AS cd_refund_cr
    ON cr.cr_refunded_cdemo_sk = cd_refund_cr.cd_demo_sk
JOIN customer_demographics AS cd_return_cr
    ON cr.cr_returning_cdemo_sk = cd_return_cr.cd_demo_sk
JOIN web_returns AS wr
    ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN customer_demographics AS cd_refund_wr
    ON wr.wr_refunded_cdemo_sk = cd_refund_wr.cd_demo_sk
JOIN customer_demographics AS cd_return_wr
    ON wr.wr_returning_cdemo_sk = cd_return_wr.cd_demo_sk
JOIN store AS s
    ON s.s_closed_date_sk = d_cr.d_date_sk
WHERE d_cr.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_cr.d_year,
    CASE
        WHEN d_cr.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END,
    s.s_state,
    s.s_city,
    cd_refund_cr.cd_gender,
    cd_return_cr.cd_gender
HAVING
    SUM(cr.cr_return_amount) > 5000
    OR SUM(wr.wr_return_amt) > 3000
ORDER BY total_catalog_return_amount DESC
LIMIT 100
