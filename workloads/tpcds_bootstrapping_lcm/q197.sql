SELECT
    cc.cc_division_name,
    cc.cc_manager,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(*) AS return_count,
    SUM(w.wr_return_amt) AS total_return_amount,
    SUM(w.wr_net_loss) AS total_net_loss,
    AVG(cd_ret.cd_purchase_estimate) AS avg_purchase_estimate_returning,
    AVG(cd_ref.cd_purchase_estimate) AS avg_purchase_estimate_refunded,
    CASE
        WHEN SUM(w.wr_return_amt) = 0 THEN 0
        ELSE SUM(w.wr_net_loss) / SUM(w.wr_return_amt)
    END AS net_loss_ratio
FROM web_returns w
JOIN date_dim d_ret
    ON w.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ret
    ON w.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON w.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
GROUP BY
    cc.cc_division_name,
    cc.cc_manager,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
