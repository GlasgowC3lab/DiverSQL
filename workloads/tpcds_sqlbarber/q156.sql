SELECT s.s_store_name,
       s.s_state,
       CONCAT(s.s_city, ', ', s.s_state) AS city_state,
       CASE WHEN s.s_number_employees > 200 THEN 'Very Large'
            WHEN s.s_number_employees > 100 THEN 'Large'
            ELSE 'Small' END AS store_size_category,
       ss.ss_quantity * ss.ss_sales_price AS quantity_times_price,
       ss.ss_ext_sales_price - ss.ss_ext_tax AS net_sales_excluding_tax,
       (ss.ss_ext_sales_price * s.s_tax_percentage) / 100.0 AS estimated_tax_from_store_rate,
       COALESCE(ss.ss_coupon_amt, 0) AS coupon_amount
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'NY' AND ss.ss_sold_date_sk = 2450920
