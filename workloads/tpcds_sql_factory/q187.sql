WITH city_returns AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT
    ca_state,
    ca_city,
    total_net_loss,
    total_return_amount,
    return_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) /
    SUM(total_net_loss) OVER () AS cumulative_net_loss_pct,
    CASE
        WHEN total_net_loss > 10000 THEN 'HIGH_LOSS'
        WHEN total_net_loss BETWEEN 5000 AND 10000 THEN 'MEDIUM_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category
FROM city_returns
ORDER BY net_loss_rank
LIMIT 10
