WITH returns_aggregated AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_current_month,
        d.d_month_seq,
        s.s_store_sk,
        s.s_city,
        s.s_state,
        ws_open.web_site_sk AS open_site_sk,
        ws_open.web_name AS open_site_name,
        ws_open.web_gmt_offset AS open_gmt_offset,
        ws_close.web_site_sk AS close_site_sk,
        ws_close.web_name AS close_site_name,
        ws_close.web_gmt_offset AS close_gmt_offset,
        t.t_hour,
        t.t_minute,
        t.t_shift,
        t.t_am_pm,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_quantity,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        (t.t_hour + CAST(ws_open.web_gmt_offset AS integer)) % 24 AS local_hour_open,
        (t.t_hour + CAST(ws_close.web_gmt_offset AS integer)) % 24 AS local_hour_close
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws_open ON ws_open.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_close ON ws_close.web_close_date_sk = d.d_date_sk
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_current_month,
        d.d_month_seq,
        s.s_store_sk,
        s.s_city,
        s.s_state,
        ws_open.web_site_sk,
        ws_open.web_name,
        ws_open.web_gmt_offset,
        ws_close.web_site_sk,
        ws_close.web_name,
        ws_close.web_gmt_offset,
        t.t_hour,
        t.t_minute,
        t.t_shift,
        t.t_am_pm
)

SELECT
    ra.d_date,
    ra.d_current_month,
    ra.s_city,
    ra.s_state,
    ra.open_site_name,
    ra.close_site_name,
    ra.t_shift,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.total_quantity,
    ra.avg_return_tax,
    ra.return_cnt,
    ra.local_hour_open,
    ra.local_hour_close,
    RANK() OVER (PARTITION BY ra.d_current_month ORDER BY ra.total_net_loss DESC) AS net_loss_rank,
    CASE
        WHEN ra.total_net_loss > 5000 THEN 'HIGH'
        WHEN ra.total_net_loss > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_loss_category
FROM returns_aggregated ra
WHERE ra.total_return_amount > 1000
ORDER BY ra.d_date DESC, net_loss_rank
LIMIT 100
