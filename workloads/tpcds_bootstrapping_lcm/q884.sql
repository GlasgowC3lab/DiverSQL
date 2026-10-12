WITH aggregated AS (
    SELECT
        cc.cc_state,
        cc.cc_market_manager,
        s.s_store_name,
        s.s_city,
        d_return.d_year,
        d_return.d_month_seq,
        p.p_promo_name,
        p.p_cost,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_return.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_return.d_year >= 2020
    GROUP BY
        cc.cc_state,
        cc.cc_market_manager,
        s.s_store_name,
        s.s_city,
        d_return.d_year,
        d_return.d_month_seq,
        p.p_promo_name,
        p.p_cost
)
SELECT
    cc_state,
    cc_market_manager,
    s_store_name,
    s_city,
    d_year,
    d_month_seq,
    p_promo_name,
    p_cost,
    total_net_loss,
    total_return_amount,
    distinct_tickets,
    avg_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_net_loss DESC) AS state_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
