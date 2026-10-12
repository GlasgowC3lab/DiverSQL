WITH
agg_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    WHERE cr_return_quantity > 1
    GROUP BY cr_returned_date_sk, cr_returned_time_sk, cr_refunded_customer_sk, cr_refunded_cdemo_sk
),
key_diff AS (
    SELECT cr_refunded_customer_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    EXCEPT
    SELECT cr_refunded_customer_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
),
unioned AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        cd.cd_credit_rating AS credit_rating,
        ar.cnt_returns,
        ar.total_return_amount,
        ar.total_net_loss,
        t.t_hour AS hour,
        CASE WHEN cd.cd_dep_count > 3 THEN 'HighDep' ELSE 'LowDep' END AS dep_category,
        RANK() OVER (PARTITION BY d.d_year ORDER BY ar.total_net_loss DESC) AS net_loss_rank
    FROM agg_returns ar
    JOIN date_dim d ON ar.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON ar.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ar.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND t.t_hour BETWEEN 8 AND 12
      AND p.p_channel_radio = 'N'
      AND ar.cr_refunded_customer_sk IN (SELECT cr_refunded_customer_sk FROM key_diff)

    UNION

    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        cd.cd_credit_rating AS credit_rating,
        ar.cnt_returns,
        ar.total_return_amount,
        ar.total_net_loss,
        t.t_hour AS hour,
        CASE WHEN cd.cd_dep_count > 3 THEN 'HighDep' ELSE 'LowDep' END AS dep_category,
        RANK() OVER (PARTITION BY d.d_year ORDER BY ar.total_net_loss DESC) AS net_loss_rank
    FROM agg_returns ar
    JOIN date_dim d ON ar.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON ar.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ar.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND t.t_hour BETWEEN 8 AND 12
      AND p.p_channel_tv = 'Y'
      AND ar.cr_refunded_customer_sk IN (SELECT cr_refunded_customer_sk FROM key_diff)
)
SELECT
    year,
    month_seq,
    credit_rating,
    cnt_returns,
    total_return_amount,
    total_net_loss,
    hour,
    dep_category,
    net_loss_rank
FROM unioned
ORDER BY year DESC, net_loss_rank
LIMIT 100
