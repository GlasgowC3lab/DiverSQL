WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id AS cc_call_center_id,
        cc.cc_market_manager AS cc_market_manager,
        cc.cc_state AS cc_state,
        st.s_store_name AS s_store_name,
        st.s_state AS store_state,
        p.p_promo_name AS p_promo_name,
        p.p_channel_tv AS p_channel_tv,
        dd_sold.d_year AS d_year,
        dd_sold.d_month_seq AS d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
        AVG(p.p_cost) AS avg_promo_cost,
        MIN(dd_cc_open.d_date) AS cc_open_date,
        MAX(dd_cc_closed.d_date) AS cc_closed_date,
        MAX(dd_store_closed.d_date) AS store_closed_date,
        MAX(dd_promo_start.d_date) AS promo_start_date,
        MAX(dd_promo_end.d_date) AS promo_end_date
    FROM store_sales ss
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim dd_sold
        ON ss.ss_sold_date_sk = dd_sold.d_date_sk
    JOIN date_dim dd_store_closed
        ON st.s_closed_date_sk = dd_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = dd_store_closed.d_date_sk
    JOIN date_dim dd_cc_closed
        ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
    JOIN date_dim dd_cc_open
        ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
    JOIN date_dim dd_promo_start
        ON p.p_start_date_sk = dd_promo_start.d_date_sk
    JOIN date_dim dd_promo_end
        ON p.p_end_date_sk = dd_promo_end.d_date_sk
    WHERE dd_sold.d_year = 2020
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_market_manager,
        cc.cc_state,
        st.s_store_name,
        st.s_state,
        p.p_promo_name,
        p.p_channel_tv,
        dd_sold.d_year,
        dd_sold.d_month_seq
)
SELECT
    cc_call_center_id,
    cc_market_manager,
    cc_state,
    s_store_name,
    store_state,
    p_promo_name,
    p_channel_tv,
    d_year,
    d_month_seq,
    total_ext_sales,
    total_net_profit,
    tickets_sold,
    avg_promo_cost,
    cc_open_date,
    cc_closed_date,
    store_closed_date,
    promo_start_date,
    promo_end_date,
    RANK() OVER (PARTITION BY cc_market_manager ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
