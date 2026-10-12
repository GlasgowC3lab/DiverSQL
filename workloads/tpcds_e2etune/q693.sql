WITH returns_agg AS (
    SELECT
        ca.ca_state AS state,
        t.t_shift AS shift,
        COUNT(*) AS num_returns,
        SUM(sr.sr_net_loss) AS total_return_loss,
        AVG(sr.sr_net_loss) AS avg_return_loss
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE ca.ca_gmt_offset = -7.00
      AND t.t_shift IN ('Night', 'Evening')
    GROUP BY ca.ca_state, t.t_shift
),
sales_agg AS (
    SELECT
        ca.ca_state AS state,
        t.t_shift AS shift,
        COUNT(*) AS num_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ca.ca_gmt_offset = -7.00
      AND t.t_shift IN ('Night', 'Evening')
    GROUP BY ca.ca_state, t.t_shift
)
SELECT
    r.state,
    r.shift,
    r.num_returns,
    r.total_return_loss,
    COALESCE(s.num_sales, 0) AS num_sales,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    (r.total_return_loss - COALESCE(s.total_net_profit, 0)) AS net_loss_vs_profit,
    RANK() OVER (ORDER BY (r.total_return_loss - COALESCE(s.total_net_profit, 0)) DESC) AS loss_profit_rank
FROM returns_agg r
LEFT JOIN sales_agg s
  ON r.state = s.state AND r.shift = s.shift
WHERE r.num_returns >= 5
ORDER BY net_loss_vs_profit DESC
LIMIT 15
