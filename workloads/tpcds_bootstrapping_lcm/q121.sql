WITH daily_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_current_month,
        r.r_reason_desc,
        s.s_store_name,
        s.s_state,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2018 AND 2022
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_current_month,
        r.r_reason_desc,
        s.s_store_name,
        s.s_state
)
SELECT
    da.d_date,
    da.d_year,
    da.d_month_seq,
    da.d_current_month,
    da.r_reason_desc,
    da.s_store_name,
    da.s_state,
    da.total_return_amt,
    da.total_return_qty,
    da.total_net_loss,
    da.total_inventory_qty,
    da.distinct_items,
    da.distinct_orders,
    (da.total_return_qty * 100.0 / NULLIF(da.total_inventory_qty, 0)) AS return_qty_pct,
    CASE
        WHEN (da.total_return_qty * 100.0 / NULLIF(da.total_inventory_qty, 0)) > 5 THEN 'High'
        ELSE 'Low'
    END AS return_rate_category,
    ROW_NUMBER() OVER (PARTITION BY da.r_reason_desc ORDER BY da.total_return_amt DESC) AS rank_by_reason,
    RANK() OVER (ORDER BY da.total_return_amt DESC) AS overall_rank
FROM daily_agg da
ORDER BY overall_rank
LIMIT 100
