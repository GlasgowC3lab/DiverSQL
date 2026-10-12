WITH return_metrics AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        i.i_category,
        i.i_item_id,
        r.r_reason_desc,
        s.s_store_id,
        s.s_state,
        SUM(wr.wr_return_quantity)            AS total_qty,
        SUM(wr.wr_return_amt)                 AS total_return_amt,
        SUM(wr.wr_net_loss)                   AS total_net_loss,
        AVG(wr.wr_fee)                        AS avg_fee,
        COUNT(DISTINCT wr.wr_order_number)    AS distinct_orders
    FROM web_returns wr
    JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i       ON wr.wr_item_sk          = i.i_item_sk
    JOIN reason r     ON wr.wr_reason_sk        = r.r_reason_sk
    JOIN store s      ON s.s_closed_date_sk     = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        i.i_category,
        i.i_item_id,
        r.r_reason_desc,
        s.s_store_id,
        s.s_state
)
SELECT
    rm.d_year,
    rm.d_quarter_name,
    rm.i_category,
    rm.r_reason_desc,
    rm.s_state,
    rm.total_qty,
    rm.total_return_amt,
    rm.total_net_loss,
    rm.avg_fee,
    rm.distinct_orders,
    RANK() OVER (PARTITION BY rm.d_year, rm.d_quarter_name, rm.i_category
                 ORDER BY rm.total_net_loss DESC) AS net_loss_rank
FROM return_metrics rm
WHERE rm.total_net_loss > 500
ORDER BY rm.d_year, rm.d_quarter_name, rm.i_category, net_loss_rank
LIMIT 100
