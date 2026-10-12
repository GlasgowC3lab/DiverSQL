SELECT
    agg.d_date,
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_id,
    agg.s_store_name,
    agg.t_hour,
    agg.t_shift,
    agg.total_return_amount,
    agg.total_return_qty,
    agg.avg_inventory_on_hand,
    agg.return_to_inventory_ratio,
    ROW_NUMBER() OVER (PARTITION BY agg.d_date ORDER BY agg.total_return_amount DESC) AS store_return_rank
FROM (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        t.t_hour,
        t.t_shift,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
        SUM(wr.wr_return_amt) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS return_to_inventory_ratio
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2018 AND 2020
      AND wr.wr_return_amt > 0
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        t.t_hour,
        t.t_shift
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
