SELECT
    d_sales.d_year,
    d_sales.d_moy,
    s.s_division_name,
    cc.cc_market_manager,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cc.cc_call_center_id) AS call_center_cnt,
    COUNT(DISTINCT s.s_store_id) FILTER (WHERE d_store_closed.d_date_sk IS NULL OR d_store_closed.d_date_sk > d_sales.d_date_sk) AS open_store_cnt
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
GROUP BY ROLLUP (d_sales.d_year, d_sales.d_moy, s.s_division_name, cc.cc_market_manager)
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY d_sales.d_year, d_sales.d_moy
LIMIT 200
