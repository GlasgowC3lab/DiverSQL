WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk,
           'catalog' AS sales_chan
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_promo_sk,
           NULL AS call_center_sk,
           'store' AS sales_chan
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_promo_sk,
           NULL AS call_center_sk,
           'web' AS sales_chan
    FROM web_sales ws
),
all_returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_returning_customer_sk AS customer_sk,
           cr.cr_net_loss AS net_loss,
           'catalog' AS return_chan
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_customer_sk,
           sr.sr_net_loss,
           'store' AS return_chan
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_refunded_customer_sk,
           wr.wr_net_loss,
           'web' AS return_chan
    FROM web_returns wr
),
returns_by_cust_item_year AS (
    SELECT r.customer_sk,
           r.item_sk,
           d.d_year AS year,
           SUM(r.net_loss) AS total_return_loss,
           COUNT(*) AS return_cnt
    FROM all_returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY r.customer_sk, r.item_sk, d.d_year
),
sales_by_cust_item_year AS (
    SELECT s.customer_sk,
           s.item_sk,
           d.d_year AS year,
           SUM(s.net_paid) AS total_sales,
           SUM(s.net_profit) AS total_profit,
           COUNT(*) AS sales_cnt,
           COUNT(DISTINCT s.promo_sk) AS distinct_promos,
           MAX(s.sales_chan) AS sales_chan,
           MAX(s.call_center_sk) AS call_center_sk
    FROM all_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY s.customer_sk, s.item_sk, d.d_year
),
combined_sales AS (
    SELECT s.customer_sk,
           s.item_sk,
           s.year,
           s.total_sales,
           s.total_profit,
           s.sales_cnt,
           s.distinct_promos,
           s.sales_chan,
           s.call_center_sk,
           COALESCE(r.total_return_loss, 0) AS total_return_loss,
           COALESCE(r.return_cnt, 0) AS return_cnt,
           (s.total_profit - COALESCE(r.total_return_loss, 0)) AS profit_after_returns
    FROM sales_by_cust_item_year s
    LEFT JOIN returns_by_cust_item_year r
      ON s.customer_sk = r.customer_sk
     AND s.item_sk = r.item_sk
     AND s.year = r.year
),
customer_sales AS (
    SELECT cs.customer_sk,
           cs.year,
           c.c_customer_id,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
           COALESCE(c.c_birth_year, 1900) AS birth_year,
           cs.item_sk,
           i.i_category,
           i.i_product_name,
           cs.total_sales,
           cs.total_profit,
           cs.total_return_loss,
           cs.profit_after_returns,
           cs.sales_cnt,
           cs.distinct_promos,
           cs.sales_chan,
           CASE 
               WHEN cs.profit_after_returns > 10000 THEN 'HIGH'
               WHEN cs.profit_after_returns > 0 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS profit_level,
           CASE 
               WHEN cs.call_center_sk IS NOT NULL THEN cc.cc_name
               ELSE NULL
           END AS call_center_name,
           ROW_NUMBER() OVER (PARTITION BY cs.year ORDER BY cs.profit_after_returns DESC) AS profit_rank,
           (SELECT SUM(total_sales) FROM combined_sales cs2 WHERE cs2.customer_sk = cs.customer_sk) AS customer_total_sales_all_years,
           (SELECT AVG(cs3.profit_after_returns)
            FROM combined_sales cs3
            JOIN item i3 ON cs3.item_sk = i3.i_item_sk
            WHERE cs3.customer_sk = cs.customer_sk
              AND i3.i_category = i.i_category
              AND cs3.year = cs.year) AS avg_category_profit_this_year,
           (cs.profit_after_returns / NULLIF((SELECT SUM(profit_after_returns)
                                             FROM combined_sales cs4
                                             WHERE cs4.customer_sk = cs.customer_sk
                                               AND cs4.year = cs.year), 0)) AS profit_share_of_customer_year
    FROM combined_sales cs
    JOIN customer c ON cs.customer_sk = c.c_customer_sk
    LEFT JOIN item i ON cs.item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.call_center_sk = cc.cc_call_center_sk
    WHERE cs.year = 2001
)
SELECT *
FROM customer_sales
WHERE profit_rank <= 10

UNION ALL

SELECT 
    c.c_customer_sk AS customer_sk,
    NULL AS year,
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    COALESCE(c.c_birth_year, 1900) AS birth_year,
    NULL AS item_sk,
    NULL AS i_category,
    NULL AS i_product_name,
    CAST(0 AS decimal(7,2)) AS total_sales,
    CAST(0 AS decimal(7,2)) AS total_profit,
    CAST(0 AS decimal(7,2)) AS total_return_loss,
    CAST(0 AS decimal(7,2)) AS profit_after_returns,
    0 AS sales_cnt,
    0 AS distinct_promos,
    NULL AS sales_chan,
    NULL AS profit_level,
    NULL AS call_center_name,
    NULL AS profit_rank,
    CAST(0 AS decimal(7,2)) AS customer_total_sales_all_years,
    NULL AS avg_category_profit_this_year,
    NULL AS profit_share_of_customer_year
FROM customer c
LEFT JOIN combined_sales cs ON c.c_customer_sk = cs.customer_sk AND cs.year = 2001
WHERE cs.customer_sk IS NULL
  AND c.c_preferred_cust_flag = 'Y'
ORDER BY profit_rank NULLS LAST, total_sales DESC
LIMIT 100
