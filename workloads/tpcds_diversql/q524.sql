WITH joined_data AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_store_sk,
       s.s_market_desc,
       s.s_store_sk AS s_store_sk,
       cd.cd_gender,
       cp.cp_department,
       cr.cr_return_amount,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_ext_sales_price DESC) AS rn_sales,
       RANK() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS rnk_return
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN catalog_returns cr ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE s.s_market_desc LIKE '%Financial%'
     AND cd.cd_gender = 'F'
     AND cp.cp_type = 'A'
     AND cr.cr_return_amount > 500
     AND ss.ss_ext_sales_price BETWEEN 1000 AND 8000
),

lateral_data AS (
   SELECT jd.*, lt.highest_profit
   FROM joined_data jd
   CROSS JOIN LATERAL (
        SELECT max(ss2.ss_net_profit) AS highest_profit
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = jd.ss_store_sk
          AND ss2.ss_sold_date_sk = jd.ss_sold_date_sk
   ) lt
),

first_set AS (
   SELECT
       s_store_sk,
       s_market_desc,
       cd_gender,
       cp_department,
       cr_return_amount,
       rn_sales,
       rnk_return,
       highest_profit
   FROM lateral_data
   WHERE rn_sales <= 10
),

second_set AS (
   SELECT
       s_store_sk,
       s_market_desc,
       cd_gender,
       cp_department,
       cr_return_amount,
       rn_sales,
       rnk_return,
       highest_profit
   FROM lateral_data
   WHERE rnk_return <= 5
),

combined AS (
   SELECT * FROM first_set
   UNION
   SELECT * FROM second_set
),

filtered_excluding AS (
   SELECT * FROM combined
   EXCEPT
   SELECT * FROM (
        SELECT * FROM combined WHERE cr_return_amount < 1000
   )
)
SELECT *
FROM filtered_excluding
ORDER BY cr_return_amount DESC, s_store_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
