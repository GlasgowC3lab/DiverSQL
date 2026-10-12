WITH monthly_customer_agg AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_moy AS month,
        COUNT(sr.sr_ticket_number) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        CASE
            WHEN d.d_moy BETWEEN 1 AND 3 THEN 'Q1'
            WHEN d.d_moy BETWEEN 4 AND 6 THEN 'Q2'
            WHEN d.d_moy BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS quarter
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY c.c_customer_id, d.d_year, d.d_moy
)
SELECT
    c_customer_id,
    d_year,
    month,
    return_cnt,
    total_net_loss,
    total_return_amount,
    avg_net_loss,
    quarter,
    RANK() OVER (PARTITION BY d_year, month ORDER BY total_net_loss DESC) AS net_loss_rank_month,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank_year
FROM monthly_customer_agg
WHERE return_cnt > 5
ORDER BY d_year, month, net_loss_rank_month
