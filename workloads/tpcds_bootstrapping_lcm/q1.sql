SELECT
    cc.cc_market_manager || ' - ' || s.s_state AS manager_state,
    d_sold.d_year,
    hd.hd_buy_potential,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(CASE WHEN ss.ss_ext_discount_amt > 0 THEN ss.ss_ext_discount_amt ELSE 0 END) AS total_discount,
    SUM(ss.ss_ext_tax) AS total_tax
FROM call_center cc
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    cc.cc_market_manager || ' - ' || s.s_state,
    d_sold.d_year,
    hd.hd_buy_potential
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
