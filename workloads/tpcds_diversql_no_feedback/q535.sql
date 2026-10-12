WITH sales_by_customer AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_birth_year AS birth_year,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_list_price) AS avg_list_price
    FROM tpcds.customer c
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_last_review_date BETWEEN 2452400 AND 2452600
      AND c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ext_sales_price > 1000
      AND ws.ws_coupon_amt < 1500
      AND ws.ws_list_price >= 50
    GROUP BY CUBE (c.c_customer_id, c.c_birth_year, ws.ws_sold_date_sk)
),
agg_over_cubes AS (
    SELECT
        birth_year,
        sold_date_sk,
        SUM(total_sales) AS sum_sales,
        AVG(total_sales) AS avg_sales,
        COUNT(DISTINCT customer_id) AS cust_cnt
    FROM sales_by_customer
    GROUP BY CUBE (birth_year, sold_date_sk)
)
SELECT
    birth_year,
    sold_date_sk,
    sum_sales,
    avg_sales,
    cust_cnt
FROM agg_over_cubes
WHERE sum_sales > 20000
  AND avg_sales > 3000
  AND cust_cnt >= 5
  AND birth_year IS NOT NULL
  AND sold_date_sk IS NOT NULL
ORDER BY sum_sales DESC
LIMIT 100
