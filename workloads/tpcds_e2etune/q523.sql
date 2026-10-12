WITH agg AS (
    SELECT
        w.w_country,
        ib.ib_income_band_sk,
        cp.cp_type,
        COUNT(DISTINCT wr.wr_order_number) AS num_orders,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM
        web_returns wr
        JOIN warehouse w ON wr.wr_returning_addr_sk = w.w_warehouse_sk
        JOIN web_site ws ON wr.wr_web_page_sk = ws.web_site_sk
        JOIN catalog_page cp ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
        JOIN income_band ib ON wr.wr_return_amt_inc_tax BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE
        cp.cp_type = 'monthly'
        AND wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY
        w.w_country,
        ib.ib_income_band_sk,
        cp.cp_type
)
SELECT
    w_country,
    ib_income_band_sk,
    cp_type,
    num_orders,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    RANK() OVER (PARTITION BY cp_type ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
