WITH agg AS (
    SELECT
        td.t_shift AS shift,
        cd.cd_education_status AS education,
        cd.cd_marital_status AS marital_status,
        COUNT(*) AS return_count,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND hd.hd_buy_potential = 'High'
    GROUP BY td.t_shift, cd.cd_education_status, cd.cd_marital_status
    HAVING SUM(sr.sr_net_loss) > 0
)
SELECT
    shift,
    education,
    marital_status,
    return_count,
    total_return_quantity,
    total_return_amount,
    avg_return_quantity,
    total_net_loss,
    distinct_tickets,
    RANK() OVER (PARTITION BY shift ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
