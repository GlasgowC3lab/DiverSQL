WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        t.t_hour,
        hd.hd_income_band_sk,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt_inc_tax > 0
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state, t.t_hour, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        t.t_hour,
        hd.hd_income_band_sk,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_amt_inc_tax > 0
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour, hd.hd_income_band_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.t_hour,
    s.hd_income_band_sk,
    s.store_return_amt,
    s.store_net_loss,
    s.store_return_cnt,
    COALESCE(w.web_return_amt, 0) AS web_return_amt,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    COALESCE(w.web_return_cnt, 0) AS web_return_cnt,
    ROUND(100.0 * s.store_return_amt / (s.store_return_amt + COALESCE(w.web_return_amt, 0)), 2) AS pct_store_of_total,
    RANK() OVER (PARTITION BY s.t_hour ORDER BY s.store_return_amt DESC) AS store_rank_by_hour
FROM store_agg s
LEFT JOIN web_agg w
    ON s.t_hour = w.t_hour
   AND s.hd_income_band_sk = w.hd_income_band_sk
WHERE s.store_return_amt > 500
ORDER BY s.t_hour, store_rank_by_hour
LIMIT 200
