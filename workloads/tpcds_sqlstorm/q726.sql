WITH
store_monthly AS (
 SELECT
   s.s_store_sk,
   s.s_store_name,
   d.d_year,
   d.d_month_seq,
   CONCAT(CAST(d.d_year AS VARCHAR), '-', format('%02d', d.d_month_seq)) AS year_month,
   COALESCE(SUM(ss.ss_net_profit),0) AS gross_profit,
   COALESCE(SUM(ss.ss_quantity),0) AS total_quantity
 FROM store s
 LEFT JOIN store_sales ss
   ON s.s_store_sk = ss.ss_store_sk
 LEFT JOIN date_dim d
   ON ss.ss_sold_date_sk = d.d_date_sk
 GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
store_returns_monthly AS (
 SELECT
   sr.sr_store_sk,
   d.d_year,
   d.d_month_seq,
   COALESCE(SUM(sr.sr_net_loss),0) AS total_returns_loss
 FROM store_returns sr
 JOIN date_dim d
   ON sr.sr_returned_date_sk = d.d_date_sk
 GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
store_with_return AS (
 SELECT
   sm.s_store_sk,
   sm.s_store_name,
   sm.d_year,
   sm.d_month_seq,
   sm.year_month,
   sm.gross_profit,
   sm.total_quantity,
   COALESCE(sr.total_returns_loss,0) AS total_returns_loss,
   sm.gross_profit - COALESCE(sr.total_returns_loss,0) AS net_profit
 FROM store_monthly sm
 LEFT JOIN store_returns_monthly sr
   ON sm.s_store_sk = sr.sr_store_sk
   AND sm.d_year = sr.d_year
   AND sm.d_month_seq = sr.d_month_seq
),
store_calc AS (
 SELECT
   swr.*,
   LAG(net_profit) OVER (PARTITION BY swr.s_store_sk ORDER BY swr.d_year, swr.d_month_seq) AS prev_net_profit,
   CASE 
     WHEN swr.net_profit > 0 THEN 'PROFIT'
     WHEN swr.net_profit < 0 THEN 'LOSS'
     ELSE 'BREAK_EVEN'
   END AS profit_indicator,
   (swr.net_profit - COALESCE(LAG(swr.net_profit) OVER (PARTITION BY swr.s_store_sk ORDER BY swr.d_year, swr.d_month_seq),0)) AS profit_change,
   RANK() OVER (PARTITION BY swr.d_year, swr.d_month_seq ORDER BY swr.net_profit DESC) AS profit_rank_month,
   ROW_NUMBER() OVER (PARTITION BY swr.s_store_sk ORDER BY swr.net_profit DESC) AS store_profit_rank
 FROM store_with_return swr
),
customer_sales_union AS (
 SELECT ss.ss_customer_sk AS customer_sk, ss.ss_net_paid AS net_paid
 FROM store_sales ss
 UNION ALL
 SELECT ws.ws_bill_customer_sk, ws.ws_net_paid
 FROM web_sales ws
 UNION ALL
 SELECT cs.cs_bill_customer_sk, cs.cs_net_paid
 FROM catalog_sales cs
),
customer_agg AS (
 SELECT cs.customer_sk,
        COALESCE(SUM(cs.net_paid),0) AS total_net_paid,
        COUNT(*) AS txn_cnt
 FROM customer_sales_union cs
 GROUP BY cs.customer_sk
),
top_customer AS (
 SELECT ca.customer_sk,
        ca.total_net_paid,
        ca.txn_cnt,
        RANK() OVER (ORDER BY ca.total_net_paid DESC) AS total_net_paid_rank
 FROM customer_agg ca
 ORDER BY ca.total_net_paid DESC
 LIMIT 10
),
customer_detail AS (
 SELECT
   t.customer_sk,
   c.c_customer_id,
   CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
   cd.cd_gender,
   cd.cd_education_status,
   t.total_net_paid,
   t.txn_cnt,
   t.total_net_paid_rank,
   CASE
     WHEN t.total_net_paid_rank <= 3 THEN 'VIP'
     WHEN t.total_net_paid_rank <= 10 THEN 'GOLD'
     ELSE 'SILVER'
   END AS tier
 FROM top_customer t
 JOIN customer c ON t.customer_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT
   sc.s_store_sk,
   sc.s_store_name,
   sc.year_month,
   sc.net_profit,
   sc.prev_net_profit,
   sc.profit_change,
   sc.profit_rank_month,
   sc.store_profit_rank,
   sc.profit_indicator,
   CASE WHEN sc.net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category,
   COALESCE(CONCAT('STORE_', REPLACE(sc.s_store_name,' ','_'), '_', sc.year_month), 'UNKNOWN') AS unique_key,
   (SELECT AVG(net_profit) FROM store_calc WHERE s_store_sk = sc.s_store_sk) AS avg_store_monthly_profit,
   (SELECT COUNT(*) FROM store_calc sc2 WHERE sc2.s_store_sk = sc.s_store_sk AND sc2.net_profit > sc.net_profit) + 1 AS higher_profit_months_count,
   CASE WHEN EXISTS (
       SELECT 1
       FROM store_sales ss2
       JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
       WHERE ss2.ss_store_sk = sc.s_store_sk
         AND d2.d_year = sc.d_year
         AND d2.d_month_seq = sc.d_month_seq
         AND ss2.ss_customer_sk IN (SELECT customer_sk FROM top_customer)
   ) THEN 'YES' ELSE 'NO' END AS top_customer_present
FROM store_calc sc
WHERE sc.profit_rank_month <= 5 OR sc.store_profit_rank <= 5
ORDER BY sc.net_profit DESC
