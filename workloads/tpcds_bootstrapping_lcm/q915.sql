WITH daily_store_returns AS (
    SELECT
        d.d_date AS open_date,
        d_close.d_date AS close_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        ws.web_name,
        ws.web_country,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM date_dim d
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        d.d_date,
        d_close.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        ws.web_name,
        ws.web_country
)
SELECT
    dsr.open_date,
    dsr.close_date,
    dsr.d_year,
    dsr.s_store_id,
    dsr.s_city,
    dsr.web_name,
    dsr.web_country,
    dsr.total_return_amount_inc_tax,
    dsr.total_net_loss,
    dsr.return_count,
    ROW_NUMBER() OVER (PARTITION BY dsr.open_date ORDER BY dsr.total_return_amount_inc_tax DESC) AS store_rank
FROM daily_store_returns dsr
WHERE dsr.total_return_amount_inc_tax > 0
ORDER BY dsr.open_date, store_rank
LIMIT 100
