WITH return_stats AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        r.r_reason_desc AS return_reason,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM call_center cc
    JOIN date_dim d_cc
        ON cc.cc_closed_date_sk = d_cc.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc.d_date_sk
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_date >= DATE '2020-01-01'
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    call_center_name,
    call_center_city,
    store_name,
    store_city,
    return_reason,
    d_year,
    d_month_seq,
    total_net_loss,
    total_return_amount_inc_tax,
    distinct_tickets,
    ROUND(total_net_loss / NULLIF(distinct_tickets, 0), 2) AS avg_loss_per_ticket,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank_by_year
FROM return_stats
ORDER BY d_year, loss_rank_by_year
