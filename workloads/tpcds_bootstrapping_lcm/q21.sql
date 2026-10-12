SELECT
    d_sales.d_year,
    cc.cc_market_manager,
    s.s_city,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    AVG(cc.cc_tax_percentage) AS avg_tax_percentage,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_sales.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sales.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
GROUP BY d_sales.d_year, cc.cc_market_manager, s.s_city
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
