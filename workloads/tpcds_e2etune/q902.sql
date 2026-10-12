WITH hourly_returns AS (
    SELECT
        td.t_hour,
        rd.cd_gender AS returning_gender,
        fd.cd_credit_rating AS refunded_credit_rating,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics rd ON cr.cr_returning_cdemo_sk = rd.cd_demo_sk
    JOIN customer_demographics fd ON cr.cr_refunded_cdemo_sk = fd.cd_demo_sk
    WHERE cr.cr_fee > 20
      AND td.t_hour BETWEEN 8 AND 20
      AND fd.cd_credit_rating = 'A'
    GROUP BY td.t_hour, rd.cd_gender, fd.cd_credit_rating
)
SELECT
    t_hour,
    returning_gender,
    total_net_loss,
    total_refunded_cash,
    avg_fee,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY returning_gender ORDER BY total_net_loss DESC) AS loss_rank
FROM hourly_returns
WHERE total_net_loss > 100
ORDER BY returning_gender, loss_rank
