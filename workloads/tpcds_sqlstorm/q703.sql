WITH unified_sales AS (
  SELECT cs.cs_sold_date_sk AS sale_date_sk,
         cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_ext_sales_price AS ext_sales_price,
         cs.cs_ext_discount_amt AS ext_discount_amt,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_customer_sk,
         ss.ss_item_sk,
         ss.ss_ext_sales_price,
         ss.ss_ext_discount_amt,
         ss.ss_net_paid,
         ss.ss_net_profit
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_bill_customer_sk,
         ws.ws_item_sk,
         ws.ws_ext_sales_price,
         ws.ws_ext_discount_amt,
         ws.ws_net_paid,
         ws.ws_net_profit
  FROM web_sales ws
),
unified_returns AS (
  SELECT cr.cr_returned_date_sk AS return_date_sk,
         cr.cr_returning_customer_sk AS customer_sk,
         cr.cr_item_sk AS item_sk,
         cr.cr_return_amount AS return_amount,
         cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_customer_sk,
         sr.sr_item_sk,
         sr.sr_return_amt,
         sr.sr_net_loss
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_returning_customer_sk,
         wr.wr_item_sk,
         wr.wr_return_amt,
         wr.wr_net_loss
  FROM web_returns wr
),
customer_latest_sales AS (
  SELECT s.customer_sk,
         MAX(d.d_date) AS latest_sale_date
  FROM unified_sales s
  LEFT JOIN date_dim d ON s.sale_date_sk = d.d_date_sk
  GROUP BY s.customer_sk
),
customer_sales_agg AS (
  SELECT s.customer_sk,
         COUNT(*) AS total_transactions,
         COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
         SUM(s.ext_sales_price) AS total_sales_amount,
         SUM(s.ext_discount_amt) AS total_discount_amount,
         SUM(s.net_paid) AS total_net_paid,
         SUM(s.net_profit) AS total_net_profit,
         AVG(s.ext_discount_amt / NULLIF(s.ext_sales_price, 0)) AS avg_discount_ratio,
         MIN(s.ext_sales_price) AS min_sale_price,
         MAX(s.ext_sales_price) AS max_sale_price,
         CASE WHEN SUM(s.net_profit) = 0 THEN NULL
              ELSE SUM(s.ext_sales_price * s.net_profit) / SUM(s.net_profit)
         END AS weighted_avg_price
  FROM unified_sales s
  GROUP BY s.customer_sk
),
customer_returns_agg AS (
  SELECT r.customer_sk,
         COUNT(*) AS total_returns,
         COUNT(DISTINCT r.item_sk) AS distinct_items_returned,
         SUM(r.return_amount) AS total_return_amount,
         SUM(r.net_loss) AS total_net_loss
  FROM unified_returns r
  GROUP BY r.customer_sk
),
customer_sales_returns_full AS (
  SELECT COALESCE(sales.customer_sk, returns.customer_sk) AS customer_sk,
         sales.total_transactions,
         sales.distinct_items_sold,
         sales.total_sales_amount,
         sales.total_discount_amount,
         sales.total_net_paid,
         sales.total_net_profit,
         sales.avg_discount_ratio,
         sales.min_sale_price,
         sales.max_sale_price,
         sales.weighted_avg_price,
         returns.total_returns,
         returns.distinct_items_returned,
         returns.total_return_amount,
         returns.total_net_loss
  FROM customer_sales_agg sales
  FULL OUTER JOIN customer_returns_agg returns
    ON sales.customer_sk = returns.customer_sk
),
customer_final AS (
  SELECT c.c_customer_id,
         COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_name,
         ca.ca_city,
         ca.ca_state,
         COALESCE(csr.total_sales_amount, 0) AS total_sales_amount,
         COALESCE(csr.total_return_amount, 0) AS total_return_amount,
         COALESCE(csr.total_net_profit, 0) - COALESCE(csr.total_net_loss, 0) AS net_profit_adjusted,
         COALESCE(csr.avg_discount_ratio, 0) AS avg_discount_ratio,
         COALESCE(csr.distinct_items_sold, 0) - COALESCE(csr.distinct_items_returned, 0) AS net_distinct_items,
         latest.latest_sale_date,
         RANK() OVER (ORDER BY COALESCE(csr.total_net_profit, 0) - COALESCE(csr.total_net_loss, 0) DESC) AS profit_rank,
         (SELECT COUNT(DISTINCT s2.item_sk)
          FROM unified_sales s2
          WHERE s2.customer_sk = c.c_customer_sk
            AND NOT EXISTS (
              SELECT 1 FROM unified_returns r2
              WHERE r2.customer_sk = s2.customer_sk
                AND r2.item_sk = s2.item_sk
            )
         ) AS never_returned_item_count,
         CASE
           WHEN ca.ca_city IS NULL OR ca.ca_state IS NULL THEN 'UNKNOWN'
           ELSE regexp_replace(lower(ca.ca_city) || '_' || lower(ca.ca_state), '[^a-z0-9_]', '')
         END AS location_code,
         CASE WHEN COALESCE(csr.total_sales_amount, 0) = 0 THEN NULL
              ELSE COALESCE(csr.total_sales_amount, 0) / NULLIF(csr.total_transactions, 0)
         END AS avg_sale_amount_per_transaction,
         CASE
           WHEN COALESCE(csr.total_transactions, 0) > 0 AND COALESCE(csr.total_returns, 0) = 0 THEN 'SALES_ONLY'
           WHEN COALESCE(csr.total_transactions, 0) = 0 AND COALESCE(csr.total_returns, 0) > 0 THEN 'RETURNS_ONLY'
           WHEN COALESCE(csr.total_transactions, 0) > 0 AND COALESCE(csr.total_returns, 0) > 0 THEN 'BOTH'
           ELSE 'NEVER'
         END AS sales_return_flag
  FROM customer c
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_sales_returns_full csr ON c.c_customer_sk = csr.customer_sk
  LEFT JOIN customer_latest_sales latest ON c.c_customer_sk = latest.customer_sk
)
SELECT *
FROM (
  SELECT *
  FROM customer_final
) q
WHERE profit_rank <= 100
  AND (COALESCE(total_sales_amount, 0) > 10000 OR COALESCE(total_return_amount, 0) > 5000)
  AND (avg_discount_ratio > 0.05 OR avg_discount_ratio IS NULL)
  AND (location_code LIKE 'a%')
ORDER BY profit_rank ASC
LIMIT 100
