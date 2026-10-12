WITH returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_returned_time_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    t.t_shift,
    t.t_meal_time,
    ra.return_cnt,
    ra.total_return_amt,
    ra.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ra.total_net_loss DESC) AS store_loss_rank,
    CASE WHEN d.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    date_diff('day', d.d_date, d_close.d_date) AS days_until_site_close
FROM date_dim d
JOIN returns_agg ra
  ON ra.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON ra.wr_returned_time_sk = t.t_time_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN date_dim d_close
  ON d_close.d_date_sk = ws.web_close_date_sk
WHERE d.d_year = 2022
  AND t.t_shift IN ('Morning', 'Afternoon')
  AND ra.total_return_amt > 500
ORDER BY ra.total_net_loss DESC
LIMIT 200
