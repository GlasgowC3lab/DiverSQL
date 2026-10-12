SELECT
    cc.cc_division,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    COUNT(*) AS num_returns,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN 1 ELSE 0 END) AS multi_item_returns,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_return_quantity * wr.wr_return_amt) AS total_quantity_amount,
    COUNT(DISTINCT c_ref.c_customer_id) AS distinct_customers,
    SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_loss_per_item,
    CASE
        WHEN SUM(wr.wr_net_loss) > 0 THEN 'PROFIT'
        WHEN SUM(wr.wr_net_loss) < 0 THEN 'LOSS'
        ELSE 'BREAKEVEN'
    END AS loss_category
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2020
GROUP BY ROLLUP (cc.cc_division, s.s_state, d_ret.d_year, d_ret.d_month_seq)
HAVING SUM(wr.wr_net_loss) <> 0
ORDER BY total_net_loss DESC
LIMIT 100
