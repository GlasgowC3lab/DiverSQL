WITH returns_by_store AS (
    SELECT
        s.s_store_id,
        d_return.d_date AS return_date,
        d_return.d_year AS return_year,
        d_return.d_month_seq AS return_month_seq,
        d_store.d_date AS store_closed_date,
        d_store.d_year AS store_closed_year,
        d_store.d_month_seq AS store_closed_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_quantity) AS avg_quantity,
        AVG(t.t_hour + t.t_minute/60.0) AS avg_return_hour,
        AVG(hd_ret.hd_vehicle_count) AS avg_vehicle_count_returning,
        AVG(hd_ref.hd_vehicle_count) AS avg_vehicle_count_refunded,
        AVG(hd_ret.hd_dep_count) AS avg_dep_count_returning,
        AVG(hd_ref.hd_dep_count) AS avg_dep_count_refunded
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    GROUP BY
        s.s_store_id,
        d_return.d_date,
        d_return.d_year,
        d_return.d_month_seq,
        d_store.d_date,
        d_store.d_year,
        d_store.d_month_seq
)
SELECT
    s_store_id,
    return_date,
    return_year,
    return_month_seq,
    store_closed_date,
    store_closed_year,
    store_closed_month_seq,
    total_return_amt,
    total_net_loss,
    return_count,
    avg_quantity,
    avg_return_hour,
    avg_vehicle_count_returning,
    avg_vehicle_count_refunded,
    avg_dep_count_returning,
    avg_dep_count_refunded,
    CASE WHEN total_return_amt > 5000 THEN 'High' ELSE 'Normal' END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_amt DESC) AS rank_by_store
FROM returns_by_store
WHERE total_return_amt > 1000
ORDER BY total_return_amt DESC
LIMIT 100
