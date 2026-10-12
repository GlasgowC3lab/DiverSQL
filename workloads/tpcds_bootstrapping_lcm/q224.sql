SELECT
    d.d_date,
    COUNT(DISTINCT cc_closed.cc_call_center_sk) AS num_cc_closed,
    COUNT(DISTINCT cc_open.cc_call_center_sk) AS num_cc_opened,
    COUNT(DISTINCT s.s_store_sk) AS num_store_closed,
    COUNT(DISTINCT c_ship.c_customer_sk) AS num_customers_ship,
    COUNT(DISTINCT c_sales.c_customer_sk) AS num_customers_sales,
    SUM(p_start.p_cost) AS total_promo_start_cost,
    SUM(p_end.p_cost) AS total_promo_end_cost,
    AVG(cc_closed.cc_tax_percentage) AS avg_cc_tax_closed,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    ROW_NUMBER() OVER (ORDER BY d.d_date) AS row_num
FROM date_dim d
LEFT JOIN call_center cc_closed
    ON cc_closed.cc_closed_date_sk = d.d_date_sk
LEFT JOIN call_center cc_open
    ON cc_open.cc_open_date_sk = d.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
LEFT JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
LEFT JOIN customer c_ship
    ON c_ship.c_first_shipto_date_sk = d.d_date_sk
LEFT JOIN customer c_sales
    ON c_sales.c_first_sales_date_sk = d.d_date_sk
WHERE d.d_date >= DATE '2021-01-01'
  AND d.d_date < DATE '2022-01-01'
GROUP BY d.d_date
ORDER BY d.d_date
LIMIT 100
