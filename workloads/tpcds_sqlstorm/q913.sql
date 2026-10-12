WITH sales_union AS (
    SELECT ss_customer_sk AS customer_sk,
           ss_sold_date_sk AS date_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_sold_date_sk AS date_sk,
           ws_quantity AS quantity,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_sold_date_sk AS date_sk,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales
),
sales_agg AS (
    SELECT s.customer_sk,
           c.c_first_name,
           c.c_last_name,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           s.channel,
           SUM(s.quantity) AS total_qty,
           SUM(s.net_paid) AS total_paid,
           SUM(s.net_profit) AS total_profit
    FROM sales_union s
    JOIN customer c ON c.c_customer_sk = s.customer_sk
    JOIN date_dim d ON d.d_date_sk = s.date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND s.channel IN ('store','web')
    GROUP BY s.customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, s.channel
),
customer_sales AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_paid DESC) AS sales_rank
    FROM sales_agg
),
returns_agg AS (
    SELECT sr_customer_sk AS customer_sk,
           SUM(sr_return_quantity) AS return_qty,
           SUM(sr_return_amt) AS return_amt,
           SUM(sr_net_loss) AS net_loss
    FROM store_returns
    GROUP BY sr_customer_sk
),
top_customers AS (
    SELECT cs.customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           cs.year,
           cs.month_seq,
           cs.channel,
           cs.total_qty,
           cs.total_paid,
           cs.total_profit,
           COALESCE(r.return_qty, 0) AS return_qty,
           COALESCE(r.return_amt, 0) AS return_amt,
           COALESCE(r.net_loss, 0) AS net_loss,
           (cs.total_profit - COALESCE(r.net_loss, 0)) AS adjusted_profit,
           CASE 
               WHEN cs.total_paid > 1000000 THEN 'Platinum'
               WHEN cs.total_paid > 500000 THEN 'Gold'
               WHEN cs.total_paid > 100000 THEN 'Silver'
               ELSE 'Bronze'
           END AS tier,
           CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
           ROW_NUMBER() OVER (PARTITION BY cs.year ORDER BY cs.total_paid DESC) AS year_rank,
           (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = cs.customer_sk) AS web_return_cnt
    FROM customer_sales cs
    LEFT JOIN returns_agg r ON r.customer_sk = cs.customer_sk
    WHERE cs.sales_rank <= 10
)
SELECT *
FROM top_customers
WHERE year_rank <= 5
ORDER BY year DESC, adjusted_profit DESC
LIMIT 50
