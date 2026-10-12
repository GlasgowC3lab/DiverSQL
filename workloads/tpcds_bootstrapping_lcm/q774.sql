WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_txn_cnt,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    d_sold.d_date AS sale_date,
    d_sold.d_year AS sale_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_closed.d_date AS store_closed_date,
    cc.cc_name AS call_center_name,
    cc.cc_manager AS call_center_manager,
    d_cc_closed.d_date AS call_center_closed_date,
    ws.web_name AS website_name,
    ws.web_manager AS website_manager,
    d_web_closed.d_date AS website_closed_date,
    sa.total_net_profit,
    sa.total_sales,
    sa.sales_txn_cnt,
    sa.avg_sales_price,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank_year
FROM sales_agg sa
JOIN date_dim d_sold ON sa.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_web_closed ON ws.web_close_date_sk = d_web_closed.d_date_sk
ORDER BY d_sold.d_date, profit_rank_year
