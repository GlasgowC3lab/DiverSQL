WITH daily_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_sold_date_sk AS date_sk,
           SUM(cs.cs_ext_sales_price) AS sales_amount,
           SUM(cs.cs_quantity) AS units_sold,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_buyers
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
 daily_returns AS (
    SELECT wr.wr_item_sk AS cs_item_sk,
           wr.wr_returned_date_sk AS date_sk,
           SUM(wr.wr_return_amt) AS return_amount,
           SUM(wr.wr_return_quantity) AS units_returned,
           COUNT(*) AS return_events
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
),
 combined AS (
    SELECT s.cs_item_sk,
           s.date_sk,
           s.sales_amount,
           COALESCE(r.return_amount, 0) AS return_amount,
           s.units_sold,
           COALESCE(r.units_returned, 0) AS units_returned,
           s.distinct_buyers,
           COALESCE(r.return_events, 0) AS return_events
    FROM daily_sales s
    LEFT JOIN daily_returns r ON s.cs_item_sk = r.cs_item_sk AND s.date_sk = r.date_sk
),
 customer_demo_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_sold_date_sk AS date_sk,
           AVG(c.c_birth_month) AS avg_birth_month,
           MAX(c.c_birth_year) AS max_birth_year
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
 most_return_page_counts AS (
    SELECT wr.wr_item_sk AS cs_item_sk,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_web_page_sk,
           COUNT(*) AS cnt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk, wr.wr_web_page_sk
),
 most_return_page_per_product_date AS (
    SELECT cs_item_sk,
           date_sk,
           wr_web_page_sk
    FROM (
        SELECT cs_item_sk,
               date_sk,
               wr_web_page_sk,
               ROW_NUMBER() OVER (PARTITION BY cs_item_sk, date_sk ORDER BY cnt DESC) AS rn
        FROM most_return_page_counts
    ) t
    WHERE rn = 1
)
SELECT c.cs_item_sk,
       c.date_sk,
       c.sales_amount,
       c.return_amount,
       (c.sales_amount - c.return_amount) AS net_amount,
       c.distinct_buyers,
       c.return_events,
       SUM(c.sales_amount - c.return_amount) OVER (PARTITION BY c.cs_item_sk ORDER BY c.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net,
       AVG(c.sales_amount - c.return_amount) OVER (PARTITION BY c.cs_item_sk ORDER BY c.date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS weekly_avg_net,
       d.avg_birth_month,
       d.max_birth_year,
       wp.wp_url AS top_return_page_url
FROM combined c
LEFT JOIN customer_demo_sales d ON c.cs_item_sk = d.cs_item_sk AND c.date_sk = d.date_sk
LEFT JOIN most_return_page_per_product_date mrp ON c.cs_item_sk = mrp.cs_item_sk AND c.date_sk = mrp.date_sk
LEFT JOIN web_page wp ON mrp.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.sales_amount > 0
  AND c.distinct_buyers >= 2
ORDER BY c.cs_item_sk, c.date_sk DESC
FETCH FIRST 50 ROWS ONLY
