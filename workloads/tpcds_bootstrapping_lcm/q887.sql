WITH aggregated_returns AS (
    SELECT
        cc.cc_manager,
        cc.cc_company_name,
        cc.cc_state,
        d_cc_closed.d_year AS cc_closed_year,
        d_cc_open.d_year AS cc_open_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        i.i_brand,
        d_sr_returned.d_year AS return_year,
        d_sr_returned.d_month_seq AS return_month,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM call_center cc
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_sr_returned
        ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d_sr_returned.d_year BETWEEN 2015 AND 2020
    GROUP BY
        cc.cc_manager,
        cc.cc_company_name,
        cc.cc_state,
        d_cc_closed.d_year,
        d_cc_open.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        i.i_brand,
        d_sr_returned.d_year,
        d_sr_returned.d_month_seq
)
SELECT
    cc_manager,
    cc_company_name,
    cc_state,
    cc_closed_year,
    cc_open_year,
    s_store_name,
    s_city,
    s_state,
    i_item_id,
    i_product_name,
    i_category,
    i_class,
    i_brand,
    return_year,
    return_month,
    total_return_qty,
    total_return_amt,
    total_refunded_cash,
    total_net_loss,
    avg_return_amt,
    distinct_tickets,
    RANK() OVER (PARTITION BY cc_manager ORDER BY total_return_amt DESC) AS manager_return_rank
FROM aggregated_returns
ORDER BY total_return_amt DESC
LIMIT 100
