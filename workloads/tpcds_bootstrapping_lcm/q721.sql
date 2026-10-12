WITH returns_by_cc_store_year AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        s.s_store_id AS store_id,
        s.s_store_name,
        s.s_state,
        d_ret.d_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        AVG(hd.hd_income_band_sk) AS avg_income_band,
        MIN(d_ret.d_date) AS first_return_date,
        MAX(d_ret.d_date) AS last_return_date
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_ret.d_date BETWEEN d_cc_open.d_date AND d_store_closed.d_date
      AND d_ret.d_year = 2022
      AND s.s_gmt_offset = cc.cc_gmt_offset
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_ret.d_year
)
SELECT
    rc.call_center_id,
    rc.cc_name,
    rc.cc_market_manager,
    rc.store_id,
    rc.s_store_name,
    rc.s_state,
    rc.d_year,
    rc.total_net_loss,
    rc.total_return_amount,
    rc.total_returns,
    rc.avg_income_band,
    rc.first_return_date,
    rc.last_return_date,
    ROW_NUMBER() OVER (PARTITION BY rc.call_center_id, rc.d_year ORDER BY rc.total_net_loss DESC) AS loss_rank
FROM returns_by_cc_store_year rc
WHERE rc.total_returns > 10
ORDER BY rc.call_center_id, rc.d_year, loss_rank
LIMIT 50
