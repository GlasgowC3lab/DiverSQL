SELECT
    cc.cc_division,
    cc.cc_manager,
    s.s_market_desc,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(*) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(
        CASE
            WHEN date_diff('day', d_closure.d_date, d_ret.d_date) BETWEEN 0 AND 30
            THEN sr.sr_return_amt_inc_tax
            ELSE 0
        END
    ) AS returns_0_30_days_inc_tax,
    COUNT(
        CASE
            WHEN date_diff('day', d_closure.d_date, d_ret.d_date) BETWEEN 0 AND 30
            THEN 1
        END
    ) AS returns_0_30_days_cnt
FROM call_center cc
JOIN date_dim d_closure
    ON cc.cc_closed_date_sk = d_closure.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
WHERE cc.cc_division IS NOT NULL
GROUP BY
    cc.cc_division,
    cc.cc_manager,
    s.s_market_desc,
    d_ret.d_year,
    d_ret.d_month_seq
HAVING COUNT(*) > 0
ORDER BY total_net_loss DESC
LIMIT 100
