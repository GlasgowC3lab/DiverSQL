WITH daily_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_sold_date_sk AS date_sk,
           SUM(cs.cs_ext_sales_price) AS sales_amount,
           SUM(cs.cs_quantity) AS units_sold
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
 daily_returns AS (
    SELECT wr.wr_item_sk AS cs_item_sk,
           wr.wr_returned_date_sk AS date_sk,
           SUM(wr.wr_return_amt) AS return_amount,
           SUM(wr.wr_return_quantity) AS units_returned
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
),
 combined AS (
    SELECT s.cs_item_sk,
           s.date_sk,
           s.sales_amount,
           COALESCE(r.return_amount, 0) AS return_amount,
           s.units_sold,
           COALESCE(r.units_returned, 0) AS units_returned
    FROM daily_sales s
    LEFT JOIN daily_returns r ON s.cs_item_sk = r.cs_item_sk AND s.date_sk = r.date_sk
),
 customer_demo_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_sold_date_sk AS date_sk,
           AVG(c.c_birth_month) AS avg_birth_month,
           COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
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
       ROUND((c.sales_amount - c.return_amount) / NULLIF(c.sales_amount, 0) * 100, 2) AS net_margin_pct,
       SUM(c.sales_amount - c.return_amount) OVER (PARTITION BY c.cs_item_sk ORDER BY c.date_sk) AS running_total_net,
       LAG(c.sales_amount) OVER (PARTITION BY c.cs_item_sk ORDER BY c.date_sk) AS prev_day_sales,
       CASE
           WHEN LAG(c.sales_amount) OVER (PARTITION BY c.cs_item_sk ORDER BY c.date_sk) IS NULL THEN 'N/A'
           WHEN (c.sales_amount - LAG(c.sales_amount) OVER (PARTITION BY c.cs_item_sk ORDER BY c.date_sk)) > 1000 THEN 'Big Jump'
           ELSE 'Stable'
       END AS sales_trend,
       d.avg_birth_month,
       d.distinct_customers,
       wp.wp_url AS top_return_page_url
FROM combined c
LEFT JOIN customer_demo_sales d ON c.cs_item_sk = d.cs_item_sk AND c.date_sk = d.date_sk
LEFT JOIN most_return_page_per_product_date mrp ON c.cs_item_sk = mrp.cs_item_sk AND c.date_sk = mrp.date_sk
LEFT JOIN web_page wp ON mrp.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.sales_amount > 500
GROUP BY c.cs_item_sk, c.date_sk, c.sales_amount, c.return_amount, c.units_sold, c.units_returned, d.avg_birth_month, d.distinct_customers, wp.wp_url
ORDER BY net_amount DESC
LIMIT 50
