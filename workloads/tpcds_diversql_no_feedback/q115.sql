WITH sales_summary AS (
   SELECT
      cs.cs_sold_date_sk,
      d.d_year,
      c.c_customer_id,
      cd.cd_gender,
      SUM(cs.cs_ext_sales_price) AS total_ext_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
     AND cd.cd_gender = 'M'
     AND cs.cs_net_paid_inc_ship > 1000
   GROUP BY cs.cs_sold_date_sk, d.d_year, c.c_customer_id, cd.cd_gender
)
SELECT
   ss.d_year,
   ss.c_customer_id,
   ss.total_ext_sales,
   ss.total_profit,
   COALESCE(sr_sum.store_return_amt, 0) + COALESCE(wr_sum.web_return_amt, 0) AS total_return_amount,
   ss.total_profit - (COALESCE(sr_sum.store_return_amt, 0) + COALESCE(wr_sum.web_return_amt, 0)) AS net_profit_after_returns,
   ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.total_ext_sales DESC) AS sales_rank_year,
   SUM(COALESCE(sr_sum.store_return_amt, 0) + COALESCE(wr_sum.web_return_amt, 0)) OVER (
        PARTITION BY ss.d_year
        ORDER BY ss.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS running_return_total
FROM sales_summary ss
JOIN date_dim d2
  ON ss.cs_sold_date_sk = d2.d_date_sk
LEFT JOIN (
   SELECT
      sr.sr_returned_date_sk,
      SUM(sr.sr_return_amt) AS store_return_amt
   FROM store_returns sr
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   WHERE s.s_store_id IN (
         SELECT s2.s_store_id
         FROM store s2
         WHERE s2.s_state = 'CA'
   )
   GROUP BY sr.sr_returned_date_sk
) sr_sum
  ON sr_sum.sr_returned_date_sk = d2.d_date_sk
LEFT JOIN (
   SELECT
      wr.wr_returned_date_sk,
      SUM(wr.wr_return_amt) AS web_return_amt
   FROM web_returns wr
   WHERE wr.wr_fee > 20
   GROUP BY wr.wr_returned_date_sk
) wr_sum
  ON wr_sum.wr_returned_date_sk = d2.d_date_sk
WHERE ss.total_ext_sales > 5000
ORDER BY ss.total_ext_sales DESC
LIMIT 100
