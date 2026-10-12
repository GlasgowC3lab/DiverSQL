WITH returns_by_cc_store_month AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city AS cc_city,
        s.s_store_sk,
        s.s_store_name,
        s.s_city AS store_city,
        d_return.d_year,
        d_return.d_month_seq,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_tickets,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_fee) AS avg_fee,
        SUM(CASE WHEN sr.sr_return_amt > 500 THEN 1 ELSE 0 END) AS high_value_returns,
        SUM(sr.sr_store_credit) AS total_store_credit,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM call_center cc
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_return.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND d_return.d_date_sk BETWEEN d_cc_open.d_date_sk AND d_cc_closed.d_date_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        d_return.d_year,
        d_return.d_month_seq
)
SELECT
    r.cc_name,
    r.cc_city,
    r.s_store_name,
    r.store_city,
    r.d_year,
    r.d_month_seq,
    r.num_tickets,
    r.total_returns,
    r.total_return_amount,
    r.total_net_loss,
    r.avg_fee,
    r.high_value_returns,
    r.total_store_credit,
    r.total_refunded_cash,
    r.total_return_quantity,
    CASE
        WHEN r.total_net_loss = 0 THEN NULL
        ELSE ROUND(r.total_return_amount / NULLIF(r.total_net_loss, 0), 2)
    END AS return_to_loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY r.cc_call_center_sk ORDER BY r.total_net_loss DESC) AS store_rank_by_net_loss
FROM returns_by_cc_store_month r
ORDER BY r.cc_name, r.total_net_loss DESC
LIMIT 100
