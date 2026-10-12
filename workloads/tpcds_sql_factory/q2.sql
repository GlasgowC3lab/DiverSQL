WITH store_monthly AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_current_month,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_store_credit) AS total_store_credit,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(sr.sr_net_loss) > 5000 THEN 'High'
            WHEN SUM(sr.sr_net_loss) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_current_month, d.d_month_seq
)
SELECT
    sm.sr_store_sk,
    sm.d_year,
    sm.d_current_month,
    sm.total_net_loss,
    sm.total_return_amt,
    sm.loss_category,
    sm.loss_rank_year,
    SUM(sm.total_net_loss) OVER (PARTITION BY sm.sr_store_sk ORDER BY sm.d_year, sm.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM store_monthly sm
ORDER BY sm.d_year, sm.d_month_seq, sm.sr_store_sk
