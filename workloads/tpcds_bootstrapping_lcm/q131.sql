WITH base AS (
    SELECT
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        d.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_number_employees,
        t.t_hour,
        t.t_minute,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_count,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND t.t_am_pm = 'PM'
    GROUP BY
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        d.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_number_employees,
        t.t_hour,
        t.t_minute
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT
    base.d_date,
    base.d_day_name,
    base.d_weekend,
    base.d_quarter_name,
    base.s_store_id,
    base.s_store_name,
    base.s_number_employees,
    base.t_hour,
    base.t_minute,
    base.total_return_amount,
    base.total_return_tax,
    base.total_fee,
    base.total_net_loss,
    base.returns_count,
    base.avg_return_qty,
    CASE 
        WHEN base.total_return_amount > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_amount_category,
    ROUND(base.total_return_amount / SUM(base.total_return_amount) OVER (PARTITION BY base.d_date), 4) AS share_of_daily_returns,
    ROW_NUMBER() OVER (PARTITION BY base.d_quarter_name ORDER BY base.total_return_amount DESC) AS quarterly_store_rank
FROM base
ORDER BY base.total_return_amount DESC, base.d_date
LIMIT 200
