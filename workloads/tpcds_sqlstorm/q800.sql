WITH
customer_base AS (
  SELECT c.c_customer_sk,
         c.c_customer_id,
         COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
         ca.ca_city,
         ca.ca_state,
         ca.ca_country,
         d.d_year
  FROM customer c
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
store_sales_agg AS (
  SELECT ss_customer_sk AS c_customer_sk,
         SUM(ss.ss_net_profit) AS store_profit,
         MAX(ss.ss_sold_date_sk) AS last_store_date_sk
  FROM store_sales ss
  GROUP BY ss_customer_sk
),
web_sales_agg AS (
  SELECT ws_bill_customer_sk AS c_customer_sk,
         SUM(ws.ws_net_profit) AS web_profit,
         MAX(ws.ws_sold_date_sk) AS last_web_date_sk
  FROM web_sales ws
  GROUP BY ws_bill_customer_sk
),
catalog_sales_agg AS (
  SELECT cs_bill_customer_sk AS c_customer_sk,
         SUM(cs.cs_net_profit) AS catalog_profit,
         MAX(cs.cs_sold_date_sk) AS last_catalog_date_sk
  FROM catalog_sales cs
  GROUP BY cs_bill_customer_sk
),
sales_agg AS (
  SELECT COALESCE(s.c_customer_sk, w.c_customer_sk, c.c_customer_sk) AS c_customer_sk,
         COALESCE(s.store_profit, 0) AS store_profit,
         COALESCE(w.web_profit, 0) AS web_profit,
         COALESCE(c.catalog_profit, 0) AS catalog_profit,
         COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) + COALESCE(c.catalog_profit, 0) AS total_profit,
         GREATEST(COALESCE(s.last_store_date_sk, 0), COALESCE(w.last_web_date_sk, 0), COALESCE(c.last_catalog_date_sk, 0)) AS latest_sale_date_sk
  FROM store_sales_agg s
  FULL OUTER JOIN web_sales_agg w ON s.c_customer_sk = w.c_customer_sk
  FULL OUTER JOIN catalog_sales_agg c ON COALESCE(s.c_customer_sk, w.c_customer_sk) = c.c_customer_sk
),
returns_agg AS (
  SELECT customer_sk,
         SUM(total_return_amount) AS total_return_amount,
         SUM(total_returns) AS total_returns
  FROM (
    SELECT cr.cr_returning_customer_sk AS customer_sk,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_returning_customer_sk
    UNION ALL
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_return_amt) AS total_return_amount,
           COUNT(*) AS total_returns
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
    UNION ALL
    SELECT wr.wr_refunded_customer_sk AS customer_sk,
           SUM(wr.wr_return_amt) AS total_return_amount,
           COUNT(*) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk
  ) t
  GROUP BY customer_sk
),
most_recent_promo AS (
  SELECT
    cb.c_customer_sk,
    p.p_promo_name,
    p.p_discount_active,
    ROW_NUMBER() OVER (PARTITION BY cb.c_customer_sk ORDER BY p.p_start_date_sk DESC) AS rn
  FROM customer_base cb
  JOIN web_sales ws ON cb.c_customer_sk = ws.ws_bill_customer_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'Y'
),
eligible_customers AS (
  SELECT cb.c_customer_sk
  FROM customer_base cb
  EXCEPT
  SELECT sr2.sr_customer_sk
  FROM store_returns sr2
  WHERE sr2.sr_net_loss > 10000
),
top_customers AS (
  SELECT
    cb.c_customer_id,
    cb.full_name,
    cb.ca_city,
    cb.ca_state,
    cb.d_year,
    sa.store_profit,
    sa.web_profit,
    sa.catalog_profit,
    sa.total_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_returns, 0) AS total_returns,
    CASE WHEN COALESCE(ra.total_return_amount, 0) > 0 THEN 'YES' ELSE 'NO' END AS has_returns,
    RANK() OVER (ORDER BY sa.total_profit DESC) AS profit_rank,
    mp.p_promo_name,
    CASE
      WHEN sa.total_profit > 0 AND COALESCE(ra.total_return_amount, 0) < 1000 THEN 'Healthy'
      WHEN sa.total_profit < 0 THEN 'Loss'
      ELSE 'Neutral'
    END AS profit_status,
    (SELECT COUNT(DISTINCT ws2.ws_promo_sk)
     FROM web_sales ws2
     WHERE ws2.ws_bill_customer_sk = cb.c_customer_sk) AS distinct_web_promos,
    (sa.total_profit - COALESCE(ra.total_return_amount, 0)) AS net_profit_vs_returns,
    CASE WHEN NULLIF(sa.total_profit, 0) IS NULL THEN 'Zero Profit' ELSE 'Non-zero' END AS profit_flag,
    CONCAT('CustID:', cb.c_customer_id,
           ' Name:', cb.full_name,
           ' Profit:', CAST(sa.total_profit AS VARCHAR),
           ' Returns:', CAST(COALESCE(ra.total_return_amount, 0) AS VARCHAR)) AS summary
  FROM customer_base cb
  JOIN eligible_customers ec ON cb.c_customer_sk = ec.c_customer_sk
  LEFT JOIN sales_agg sa ON cb.c_customer_sk = sa.c_customer_sk
  LEFT JOIN returns_agg ra ON cb.c_customer_sk = ra.customer_sk
  LEFT JOIN most_recent_promo mp ON cb.c_customer_sk = mp.c_customer_sk AND mp.rn = 1
  WHERE cb.ca_country = 'United States'
    AND (cb.ca_state IS NOT NULL OR cb.ca_city IS NOT NULL)
    AND sa.total_profit IS NOT NULL
    AND sa.total_profit > 0
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = cb.c_customer_sk
        AND sr2.sr_net_loss > 0
        AND sr2.sr_return_amt > 500
    )
    AND (cb.d_year BETWEEN 2000 AND 2005)
)
SELECT *
FROM top_customers
WHERE profit_rank <= 50
ORDER BY profit_rank
LIMIT 50
