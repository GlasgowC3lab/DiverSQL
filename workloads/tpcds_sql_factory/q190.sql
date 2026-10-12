WITH state_page_stats AS (
    SELECT
        ca.ca_state,
        wp.wp_type,
        COUNT(*) AS total_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(CASE WHEN wr.wr_fee > 0 THEN wr.wr_fee END) AS avg_positive_fee,
        SUM(CASE WHEN wr.wr_fee > 0 THEN 1 ELSE 0 END) AS fee_positive_cnt,
        SUM(wr.wr_return_quantity) AS total_quantity,
        t.t_shift
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY ca.ca_state, wp.wp_type, t.t_shift
    HAVING COUNT(*) >= 10
)
SELECT
    ca_state,
    wp_type,
    t_shift,
    total_returns,
    total_net_loss,
    avg_positive_fee,
    fee_positive_cnt,
    100.0 * fee_positive_cnt / total_returns AS pct_returns_with_fee,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_state_rank,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) /
    SUM(total_net_loss) OVER () AS cumulative_net_loss_share,
    CASE
        WHEN total_net_loss > 5000 THEN 'HIGH_RISK'
        WHEN total_net_loss BETWEEN 2000 AND 5000 THEN 'MEDIUM_RISK'
        ELSE 'LOW_RISK'
    END AS risk_category
FROM state_page_stats
ORDER BY net_loss_state_rank
LIMIT 15
