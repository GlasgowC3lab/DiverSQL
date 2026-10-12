SELECT
    d.d_year,
    d.d_current_month,
    st.s_state,
    cc.cc_state,
    SUM(s.ss_net_profit) AS total_store_net_profit,
    SUM(s.ss_ext_sales_price) AS total_store_sales,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_return_net_loss,
    SUM(s.ss_net_profit) - SUM(r.cr_net_loss) AS net_profit_adjusted,
    CASE
        WHEN SUM(s.ss_ext_sales_price) = 0 THEN NULL
        ELSE (SUM(s.ss_net_profit) - SUM(r.cr_net_loss)) / SUM(s.ss_ext_sales_price)
    END AS adjusted_profit_margin
FROM
    (SELECT ss.*, ss.ss_sold_date_sk AS date_sk FROM store_sales ss) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN store st ON s.ss_store_sk = st.s_store_sk
    JOIN date_dim d_store_closed ON st.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN (SELECT cr.*, cr.cr_returned_date_sk AS date_sk FROM catalog_returns cr) r
        ON s.date_sk = r.date_sk
    JOIN call_center cc ON r.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_center_closed ON cc.cc_closed_date_sk = d_center_closed.d_date_sk
    JOIN date_dim d_center_open ON cc.cc_open_date_sk = d_center_open.d_date_sk
GROUP BY
    ROLLUP (d.d_year, d.d_current_month, st.s_state, cc.cc_state)
