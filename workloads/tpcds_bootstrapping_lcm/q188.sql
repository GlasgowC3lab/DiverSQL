SELECT
    cc.cc_market_manager,
    s.s_division_name,
    hd.hd_buy_potential,
    d_sales.d_year,
    d_sales.d_quarter_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_count,
    AVG(ss.ss_quantity) AS avg_quantity,
    CASE
        WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    (SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0)) AS profit_margin
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
WHERE
    d_sales.d_year = 2022
    AND s.s_state = 'CA'
    AND hd.hd_income_band_sk > 5
    AND cc.cc_market_manager IS NOT NULL
GROUP BY
    cc.cc_market_manager,
    s.s_division_name,
    hd.hd_buy_potential,
    d_sales.d_year,
    d_sales.d_quarter_name
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
