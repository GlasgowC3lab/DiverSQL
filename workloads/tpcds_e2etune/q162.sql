WITH store_hour_income AS (
    SELECT
        s.s_store_name,
        s.s_state,
        t.t_hour,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_visited
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    WHERE s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_amt > 100
    GROUP BY
        s.s_store_name,
        s.s_state,
        t.t_hour,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    s_store_name,
    s_state,
    t_hour,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amt,
    total_net_loss,
    return_cnt,
    avg_return_amt,
    distinct_pages_visited,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS net_loss_rank_in_hour
FROM store_hour_income
ORDER BY t_hour, net_loss_rank_in_hour
LIMIT 100
