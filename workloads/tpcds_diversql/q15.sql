WITH sales_time_agg AS (
   SELECT
       ss.ss_item_sk,
       t.t_hour,
       t.t_minute,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_quantity) AS total_qty,
       AVG(ss.ss_list_price) AS avg_list_price
   FROM store_sales ss
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE ss.ss_list_price > 30
     AND ss.ss_quantity BETWEEN 1 AND 10
     AND t.t_hour BETWEEN 6 AND 17
     AND t.t_minute IN (10, 11, 12, 15, 19)
   GROUP BY ss.ss_item_sk, t.t_hour, t.t_minute
),

sales_running AS (
   SELECT
       s.*, 
       SUM(total_sales) OVER (
           PARTITION BY t_hour 
           ORDER BY total_sales DESC 
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_sales_by_hour
   FROM sales_time_agg s
),

item_exceptions AS (
   SELECT ss_item_sk FROM store_sales WHERE ss_quantity > 5 AND ss_list_price > 40
   EXCEPT
   SELECT ss_item_sk FROM store_sales WHERE ss_quantity < 3 AND ss_list_price < 20
),

final AS (
   SELECT
       sr.ss_item_sk,
       sr.t_hour,
       sr.t_minute,
       sr.total_sales,
       sr.total_qty,
       sr.avg_list_price,
       sr.running_sales_by_hour,
       lt.extra_factor
   FROM sales_running sr
   LEFT JOIN LATERAL (
        SELECT (sr.t_minute * 0.1) AS extra_factor
   ) lt ON true
   WHERE sr.total_sales > 100
     AND sr.total_qty >= 5
     AND sr.avg_list_price < 100
     AND sr.t_hour IS NOT NULL
)

SELECT
   f.t_hour,
   f.t_minute,
   COUNT(DISTINCT f.ss_item_sk) AS distinct_items,
   SUM(f.total_sales) AS sum_sales,
   AVG(f.running_sales_by_hour) AS avg_running_sales,
   COUNT(CASE WHEN f.ss_item_sk IN (SELECT ss_item_sk FROM item_exceptions) THEN 1 END) AS exception_item_count
FROM final f
GROUP BY f.t_hour, f.t_minute
ORDER BY sum_sales DESC, f.t_hour
LIMIT 100
