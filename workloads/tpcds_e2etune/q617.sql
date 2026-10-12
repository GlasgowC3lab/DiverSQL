WITH agg AS (
    SELECT
        cc.cc_city AS city,
        cc.cc_manager AS manager,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM call_center cc
    JOIN web_returns wr
      ON wr.wr_returned_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    WHERE cc.cc_employees > 3000000
      AND wr.wr_return_amt > 0
    GROUP BY cc.cc_city, cc.cc_manager
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    city,
    manager,
    total_returns,
    total_net_loss,
    avg_return_amt,
    total_quantity,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rank_by_net_loss
FROM agg
ORDER BY total_net_loss DESC
LIMIT 20
