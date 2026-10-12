WITH returns_summary AS (
    SELECT
        cr_order_number,
        cr_returned_date_sk,
        cr_refunded_cdemo_sk,
        cr_returning_cdemo_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_fee) AS sum_fee,
        SUM(cr_net_loss) AS sum_net_loss,
        COUNT(*) AS return_count,
        AVG(cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns
    GROUP BY
        cr_order_number,
        cr_returned_date_sk,
        cr_refunded_cdemo_sk,
        cr_returning_cdemo_sk
)
SELECT
    d.d_year AS return_year,
    s.s_market_desc AS market,
    cd_ret.cd_gender AS gender,
    cd_ret.cd_marital_status AS marital_status,
    wp.wp_type AS page_type,
    COUNT(DISTINCT rs.cr_order_number) AS num_orders,
    SUM(rs.sum_return_amount) AS total_return_amount,
    SUM(rs.sum_fee) AS total_fee,
    SUM(rs.sum_net_loss) AS total_net_loss,
    AVG(rs.avg_return_quantity) AS avg_return_quantity,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(date_diff('day', d_access.d_date, d.d_date)) AS avg_days_between_creation_and_access,
    SUM(CASE WHEN rs.sum_return_amount > 100 THEN rs.sum_return_amount ELSE 0 END) AS high_return_sum,
    SUM(CASE WHEN cd_ret.cd_credit_rating = 'Excellent' THEN rs.sum_net_loss ELSE 0 END) AS net_loss_excellent_credit,
    SUM(CASE WHEN cd_ref.cd_credit_rating = 'Excellent' THEN rs.sum_return_amount ELSE 0 END) AS refunded_excellent_return_amount
FROM returns_summary rs
JOIN date_dim d ON rs.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref ON rs.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret ON rs.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    s.s_market_desc,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    wp.wp_type
HAVING SUM(rs.sum_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
