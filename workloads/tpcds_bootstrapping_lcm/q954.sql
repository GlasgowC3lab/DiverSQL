SELECT
    a.s_store_id,
    a.s_store_name,
    a.store_city,
    a.store_state,
    a.s_floor_space,
    a.r_reason_desc,
    a.return_year,
    a.return_month_seq,
    a.cc_market_manager,
    a.call_center_name,
    a.cc_city,
    a.cc_state,
    a.total_net_loss,
    a.total_return_qty,
    a.avg_return_amt,
    a.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id, a.return_year ORDER BY a.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        s.s_floor_space,
        r.r_reason_desc,
        d_return.d_year AS return_year,
        d_return.d_month_seq AS return_month_seq,
        cc.cc_market_manager,
        cc.cc_name AS call_center_name,
        cc.cc_city,
        cc.cc_state,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_shared
        ON s.s_closed_date_sk = d_shared.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_shared.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_floor_space,
        r.r_reason_desc,
        d_return.d_year,
        d_return.d_month_seq,
        cc.cc_market_manager,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state
) a
ORDER BY a.total_net_loss DESC
LIMIT 100
