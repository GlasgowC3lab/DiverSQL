WITH agg_returns AS (
    SELECT
        s.s_state AS store_state,
        cd_ret.cd_education_status AS education_status,
        d.d_year AS return_year,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cd_ret.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd_ret.cd_gender = 'M'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND t.t_meal_time = 'Evening'
    GROUP BY s.s_state, cd_ret.cd_education_status, d.d_year
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    store_state,
    education_status,
    return_year,
    total_returns,
    total_quantity,
    total_net_loss,
    avg_return_amount,
    RANK() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100
