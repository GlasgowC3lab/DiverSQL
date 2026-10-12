SELECT
    s_store_id,
    d_year,
    total_net_loss,
    total_returns,
    pct_damaged_returns,
    store_status_at_last_return,
    net_loss_rank_in_year
FROM (
    SELECT
        s.s_store_id,
        s.s_store_sk,
        d.d_year,
        MAX(d.d_date_sk) AS max_return_date_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns,
        100.0 * SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS pct_damaged_returns,
        CASE 
            WHEN s.s_closed_date_sk IS NOT NULL AND MAX(d.d_date_sk) >= s.s_closed_date_sk THEN 'Closed'
            ELSE 'Open'
        END AS store_status_at_last_return,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS net_loss_rank_in_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY s.s_store_id, s.s_store_sk, s.s_closed_date_sk, d.d_year
) t
ORDER BY d_year, net_loss_rank_in_year
