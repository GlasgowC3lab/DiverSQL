SELECT
    cc.cc_manager,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    AVG(ss.ss_quantity) AS avg_quantity,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_transactions,
    (SUM(ss.ss_ext_sales_price) - SUM(ss.ss_ext_discount_amt)) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_price_per_quantity
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND cc.cc_manager IS NOT NULL
  AND wp.wp_type = 'Product'
GROUP BY
    cc.cc_manager,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
