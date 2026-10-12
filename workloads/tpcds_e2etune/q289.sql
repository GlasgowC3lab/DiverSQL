WITH wr_enriched AS (
    SELECT
        wr.*, 
        ((wr.wr_item_sk % 5) + 1) AS sm_key,
        ((wr.wr_returning_customer_sk % 100) + 1) AS wh_key
    FROM web_returns wr
),
agg AS (
    SELECT
        sm.sm_type,
        w.w_state,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM wr_enriched wr
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = wr.sm_key
    JOIN warehouse w ON w.w_warehouse_sk = wr.wh_key
    WHERE sm.sm_carrier IN ('UPS', 'FEDEX')
      AND w.w_country = 'United States'
      AND wr.wr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY sm.sm_type, w.w_state
    HAVING COUNT(*) > 100
)
SELECT
    sm_type,
    w_state,
    num_returns,
    total_return_amt,
    avg_net_loss,
    total_quantity,
    RANK() OVER (ORDER BY avg_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank
LIMIT 20
