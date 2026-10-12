SELECT
    cc.cc_manager AS manager,
    s.s_state AS store_state,
    r.r_reason_desc AS return_reason,
    d_wr.d_year AS return_year,
    d_wr.d_current_month AS return_month,
    d_store.d_weekend AS store_closed_weekend,
    CASE
        WHEN cc.cc_state = 'CA' THEN 'California'
        WHEN cc.cc_state = 'NY' THEN 'New York'
        ELSE 'Other State'
    END AS manager_state_group,
    CASE
        WHEN date_diff('day', d_cc_open.d_date, d_wr.d_date) <= 365 THEN '0-1yr'
        WHEN date_diff('day', d_cc_open.d_date, d_wr.d_date) <= 730 THEN '1-2yr'
        ELSE '2+yr'
    END AS cc_age_bucket,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0) AS net_loss_ratio,
    AVG(date_diff('day', d_cc_open.d_date, d_wr.d_date)) AS avg_days_since_cc_open
FROM web_returns wr
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_wr.d_year BETWEEN 2000 AND 2020
GROUP BY
    cc.cc_manager,
    s.s_state,
    r.r_reason_desc,
    d_wr.d_year,
    d_wr.d_current_month,
    d_store.d_weekend,
    CASE
        WHEN cc.cc_state = 'CA' THEN 'California'
        WHEN cc.cc_state = 'NY' THEN 'New York'
        ELSE 'Other State'
    END,
    CASE
        WHEN date_diff('day', d_cc_open.d_date, d_wr.d_date) <= 365 THEN '0-1yr'
        WHEN date_diff('day', d_cc_open.d_date, d_wr.d_date) <= 730 THEN '1-2yr'
        ELSE '2+yr'
    END
ORDER BY total_return_amount DESC
LIMIT 100
