WITH returns_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        t.t_shift,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        s.s_state,
        sum(wr.wr_return_amt)          AS total_return_amount,
        sum(wr.wr_return_quantity)     AS total_return_qty,
        sum(wr.wr_net_loss)            AS total_net_loss,
        avg(wr.wr_return_tax)          AS avg_return_tax,
        count(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND s.s_state = 'CA'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        t.t_shift,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        s.s_state
)
SELECT
    d_year,
    d_month_seq,
    d_day_name,
    t_shift,
    r_reason_desc,
    s_store_name,
    s_city,
    total_return_amount,
    total_return_qty,
    total_net_loss,
    avg_return_tax,
    distinct_orders,
    (total_net_loss / nullif(total_return_amount, 0)) AS loss_to_return_ratio,
    row_number() OVER (PARTITION BY s_store_name ORDER BY total_return_amount DESC) AS rank_within_store
FROM returns_summary
ORDER BY total_return_amount DESC
LIMIT 100
