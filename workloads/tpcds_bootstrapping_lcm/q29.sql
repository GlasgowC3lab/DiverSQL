SELECT
    agg.cc_company_name,
    agg.cc_state,
    agg.return_year,
    agg.return_month_seq,
    agg.store_closed_year,
    agg.store_closed_month,
    agg.cc_open_year,
    agg.cc_open_month,
    agg.store_name,
    agg.city,
    agg.state,
    agg.t_hour,
    agg.t_meal_time,
    agg.distinct_ticket_cnt,
    agg.total_return_amount,
    agg.total_return_quantity,
    agg.avg_return_fee,
    agg.total_return_tax,
    agg.max_ship_cost,
    agg.min_return_amt_inc_tax,
    SUM(agg.total_return_amount) OVER (PARTITION BY agg.state) AS total_return_amount_by_state,
    ROW_NUMBER() OVER (PARTITION BY agg.store_name ORDER BY agg.total_return_amount DESC) AS rn_store_by_return
FROM (
    SELECT
        cc.cc_company_name,
        cc.cc_state,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        d_store.d_year AS store_closed_year,
        d_store.d_month_seq AS store_closed_month,
        d_cc_open.d_year AS cc_open_year,
        d_cc_open.d_month_seq AS cc_open_month,
        s.s_store_name AS store_name,
        s.s_city AS city,
        s.s_state AS state,
        t.t_hour,
        t.t_meal_time,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_cnt,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        AVG(sr.sr_fee) AS avg_return_fee,
        SUM(sr.sr_return_tax) AS total_return_tax,
        MAX(sr.sr_return_ship_cost) AS max_ship_cost,
        MIN(sr.sr_return_amt_inc_tax) AS min_return_amt_inc_tax
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_ret.d_year = 2022
      AND s.s_state IN ('CA', 'NY', 'TX')
    GROUP BY
        cc.cc_company_name,
        cc.cc_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_store.d_year,
        d_store.d_month_seq,
        d_cc_open.d_year,
        d_cc_open.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        t.t_hour,
        t.t_meal_time
    HAVING SUM(sr.sr_return_amt) > 1000
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
