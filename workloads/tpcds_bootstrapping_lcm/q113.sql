WITH agg AS (
    SELECT
        cc.cc_company_name,
        cc.cc_state,
        cc.cc_country,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        AVG(date_diff('day', d_cc_open.d_date, d_ret.d_date)) AS avg_days_since_cc_open,
        AVG(date_diff('day', d_store_closed.d_date, d_ret.d_date)) AS avg_days_between_store_close_and_return,
        MIN(d_ret.d_date) AS first_return_date,
        MAX(d_ret.d_date) AS last_return_date
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY
        cc.cc_company_name,
        cc.cc_state,
        cc.cc_country,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY agg.cc_country ORDER BY agg.total_return_amount DESC) AS country_rank
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
