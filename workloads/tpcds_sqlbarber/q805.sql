SELECT s.s_store_name, SUM(ss.ss_ext_sales_price) AS total_sales FROM store_sales ss JOIN store s ON ss.ss_store_sk = s.s_store_sk WHERE ss.ss_sold_date_sk = 2452125 GROUP BY s.s_store_name
