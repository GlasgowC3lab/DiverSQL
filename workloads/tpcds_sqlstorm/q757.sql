WITH unified_sales AS (
   SELECT
     s.ss_customer_sk AS customer_sk,
     s.ss_sold_date_sk AS date_sk,
     s.ss_quantity AS quantity,
     s.ss_ext_sales_price AS ext_sales_price,
     s.ss_ext_tax AS ext_tax,
     s.ss_net_profit AS net_profit,
     'store' AS channel,
     s.ss_item_sk AS item_sk
   FROM store_sales s
   UNION ALL
   SELECT
     cs.cs_bill_customer_sk AS customer_sk,
     cs.cs_sold_date_sk AS date_sk,
     cs.cs_quantity AS quantity,
     cs.cs_ext_sales_price AS ext_sales_price,
     cs.cs_ext_tax AS ext_tax,
     cs.cs_net_profit AS net_profit,
     'catalog' AS channel,
     cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   UNION ALL
   SELECT
     ws.ws_bill_customer_sk AS customer_sk,
     ws.ws_sold_date_sk AS date_sk,
     ws.ws_quantity AS quantity,
     ws.ws_ext_sales_price AS ext_sales_price,
     ws.ws_ext_tax AS ext_tax,
     ws.ws_net_profit AS net_profit,
     'web' AS channel,
     ws.ws_item_sk AS item_sk
   FROM web_sales ws
),
customer_sales_agg AS (
   SELECT
      c.c_customer_sk,
      c.c_customer_id,
      concat(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
      d.d_year,
      d.d_month_seq,
      us.channel,
      SUM(us.ext_sales_price) AS total_sales,
      SUM(us.ext_tax) AS total_tax,
      SUM(us.net_profit) AS total_profit,
      COUNT(*) AS transaction_count,
      AVG(us.quantity) AS avg_qty,
      MAX(us.ext_sales_price) AS max_sale,
      MIN(us.ext_sales_price) AS min_sale
   FROM customer c
   LEFT JOIN unified_sales us ON c.c_customer_sk = us.customer_sk
   LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
   WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
     AND d.d_year BETWEEN 1999 AND 2002
   GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      d.d_year,
      d.d_month_seq,
      us.channel
),
customer_aggregates AS (
   SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY total_sales DESC) AS sales_rank
   FROM customer_sales_agg
),
top_customers AS (
   SELECT *
   FROM customer_aggregates
   WHERE sales_rank <= 5
),
returns_combined AS (
   SELECT
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_item_sk AS item_sk,
      sr.sr_return_quantity AS quantity,
      sr.sr_return_amt + sr.sr_return_tax AS total_return_amount,
      'store' AS channel
   FROM store_returns sr
   UNION ALL
   SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity AS quantity,
      cr.cr_return_amount + cr.cr_return_tax AS total_return_amount,
      'catalog' AS channel
   FROM catalog_returns cr
   UNION ALL
   SELECT
      wr.wr_returned_date_sk AS date_sk,
      wr.wr_item_sk AS item_sk,
      wr.wr_return_quantity AS quantity,
      wr.wr_return_amt + wr.wr_return_tax AS total_return_amount,
      'web' AS channel
   FROM web_returns wr
),
customer_returns AS (
   SELECT
      c.c_customer_sk,
      d.d_year,
      d.d_month_seq,
      rc.channel,
      SUM(rc.total_return_amount) AS total_return_amount,
      COUNT(rc.total_return_amount) AS return_transactions
   FROM customer c
   JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
   LEFT JOIN returns_combined rc ON ss.ss_item_sk = rc.item_sk
                                 AND ss.ss_sold_date_sk = rc.date_sk
   LEFT JOIN date_dim d ON rc.date_sk = d.d_date_sk
   GROUP BY
      c.c_customer_sk,
      d.d_year,
      d.d_month_seq,
      rc.channel
),
final_metrics AS (
   SELECT
      tc.c_customer_sk,
      tc.c_customer_id,
      tc.full_name,
      tc.d_year,
      tc.d_month_seq,
      tc.channel,
      tc.total_sales,
      tc.total_tax,
      tc.total_profit,
      tc.transaction_count,
      tc.avg_qty,
      tc.max_sale,
      tc.min_sale,
      cr.total_return_amount,
      cr.return_transactions,
      CASE
         WHEN tc.total_sales > 0 THEN (tc.total_profit - COALESCE(cr.total_return_amount, 0)) / tc.total_sales
         ELSE NULL
      END AS profit_return_ratio,
      (SELECT COUNT(DISTINCT us2.item_sk)
       FROM unified_sales us2
       JOIN date_dim d2 ON us2.date_sk = d2.d_date_sk
       WHERE us2.customer_sk = tc.c_customer_sk
         AND us2.channel = tc.channel
         AND d2.d_year = tc.d_year
         AND d2.d_month_seq = tc.d_month_seq) AS distinct_items,
      concat('CUST_', CAST(tc.c_customer_sk AS VARCHAR)) AS cust_key
   FROM top_customers tc
   LEFT JOIN customer_returns cr
      ON tc.c_customer_sk = cr.c_customer_sk
     AND tc.d_year = cr.d_year
     AND tc.d_month_seq = cr.d_month_seq
     AND tc.channel = cr.channel
)
SELECT *
FROM final_metrics
ORDER BY profit_return_ratio DESC NULLS LAST
LIMIT 100
