WITH daily_returns AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    cc.cc_division_name,
    cc.cc_manager,
    cc.cc_tax_percentage,
    d_open.d_date AS cc_open_date,
    d_closed.d_date AS cc_closed_date,
    s.s_store_name,
    s.s_city,
    s.s_floor_space,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COALESCE(MAX(dr.total_return_amt), 0) AS total_returns,
    COALESCE(MAX(dr.total_return_loss), 0) AS total_return_loss,
    SUM(ss.ss_ext_sales_price) - COALESCE(MAX(dr.total_return_amt), 0) AS net_sales,
    RANK() OVER (
        PARTITION BY cc.cc_division_name
        ORDER BY SUM(ss.ss_ext_sales_price) - COALESCE(MAX(dr.total_return_amt), 0) DESC
    ) AS sales_rank
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open   ON cc.cc_open_date_sk   = d_open.d_date_sk
JOIN store s           ON s.s_closed_date_sk   = d_closed.d_date_sk
JOIN store_sales ss    ON ss.ss_store_sk = s.s_store_sk
                        AND ss.ss_sold_date_sk = d_closed.d_date_sk
LEFT JOIN daily_returns dr ON dr.date_sk = d_closed.d_date_sk
WHERE d_closed.d_year = 2022
GROUP BY
    cc.cc_division_name,
    cc.cc_manager,
    cc.cc_tax_percentage,
    d_open.d_date,
    d_closed.d_date,
    s.s_store_name,
    s.s_city,
    s.s_floor_space
ORDER BY net_sales DESC
LIMIT 100
