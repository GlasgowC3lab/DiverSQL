SELECT
    sub.call_center_name,
    sub.market_manager,
    sub.customer_state,
    sub.customer_country,
    sub.year,
    sub.month_seq,
    sub.store_name,
    sub.store_city,
    sub.store_state,
    sub.total_net_loss,
    sub.total_return_amount,
    sub.avg_return_qty,
    sub.distinct_tickets,
    sub.store_closed_month,
    ROW_NUMBER() OVER (PARTITION BY sub.year ORDER BY sub.total_net_loss DESC) AS loss_rank_by_year
FROM (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_market_manager AS market_manager,
        ca.ca_state AS customer_state,
        ca.ca_country AS customer_country,
        d1.d_year AS year,
        d1.d_month_seq AS month_seq,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        d2.d_current_month AS store_closed_month
    FROM call_center cc
    JOIN date_dim d1 ON cc.cc_closed_date_sk = d1.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY
        cc.cc_name,
        cc.cc_market_manager,
        ca.ca_state,
        ca.ca_country,
        d1.d_year,
        d1.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d2.d_current_month
    HAVING SUM(sr.sr_net_loss) > 0
) sub
ORDER BY sub.year DESC, sub.total_net_loss DESC
LIMIT 100
