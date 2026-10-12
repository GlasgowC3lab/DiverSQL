SELECT
    sub.cc_company_name,
    sub.cc_state,
    sub.cc_open_year,
    sub.s_store_name,
    sub.store_state,
    sub.store_closed_year,
    sub.sales_year,
    sub.sales_month,
    sub.total_sales,
    sub.total_discount,
    sub.total_quantity_sold,
    sub.total_profit,
    sub.total_return_amount,
    sub.total_return_quantity,
    sub.return_to_sales_ratio,
    ROW_NUMBER() OVER (ORDER BY sub.total_sales DESC) AS sales_rank
FROM (
    SELECT
        cc.cc_company_name,
        cc.cc_state,
        d_cc_open.d_year AS cc_open_year,
        st.s_store_name,
        st.s_state AS store_state,
        d_store_closed.d_year AS store_closed_year,
        d_sales.d_year AS sales_year,
        d_sales.d_month_seq AS sales_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
            ELSE SUM(wr.wr_return_amt) / SUM(ss.ss_ext_sales_price)
        END AS return_to_sales_ratio
    FROM
        store_sales ss
        JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN store st ON ss.ss_store_sk = st.s_store_sk
        JOIN date_dim d_store_closed ON st.s_closed_date_sk = d_store_closed.d_date_sk
        JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
        JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
    WHERE
        ss.ss_quantity > 0
    GROUP BY
        cc.cc_company_name,
        cc.cc_state,
        d_cc_open.d_year,
        st.s_store_name,
        st.s_state,
        d_store_closed.d_year,
        d_sales.d_year,
        d_sales.d_month_seq
) sub
ORDER BY sub.total_sales DESC
LIMIT 100
