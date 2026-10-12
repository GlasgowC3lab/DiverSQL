WITH store_agg AS (
    SELECT
        t.t_hour,
        p.p_channel_email,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN promotion p ON sr.sr_item_sk = p.p_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_email = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour, p.p_channel_email
),
web_agg AS (
    SELECT
        t.t_hour,
        p.p_channel_email,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN promotion p ON wr.wr_item_sk = p.p_item_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_email = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour, p.p_channel_email
)
SELECT
    COALESCE(s.t_hour, w.t_hour) AS hour_of_day,
    COALESCE(s.p_channel_email, w.p_channel_email) AS email_channel,
    COALESCE(s.store_net_loss, 0) AS store_net_loss,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
    RANK() OVER (ORDER BY (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) DESC) AS loss_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.t_hour = w.t_hour AND s.p_channel_email = w.p_channel_email
ORDER BY total_net_loss DESC
LIMIT 5
