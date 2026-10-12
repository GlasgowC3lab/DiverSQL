WITH union_sales AS (
    SELECT cs_bill_customer_sk AS cust_sk,
           cs_order_number AS order_number,
           cs_sold_date_sk AS date_sk,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           'Catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_customer_sk AS cust_sk,
           ss_ticket_number AS order_number,
           ss_sold_date_sk AS date_sk,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           'Store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS cust_sk,
           ws_order_number AS order_number,
           ws_sold_date_sk AS date_sk,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit,
           'Web' AS channel
    FROM web_sales
),
customer_sales_agg AS (
    SELECT us.cust_sk,
           SUM(us.net_paid) AS total_paid,
           SUM(us.net_profit) AS total_profit,
           COUNT(DISTINCT us.order_number) AS distinct_orders,
           COUNT(*) AS total_transactions,
           MIN(d.d_date) AS first_purchase_date,
           MAX(d.d_date) AS last_purchase_date,
           SUM(CASE WHEN us.channel = 'Web' THEN us.net_paid ELSE 0 END) AS web_paid,
           SUM(CASE WHEN us.channel = 'Store' THEN us.net_paid ELSE 0 END) AS store_paid,
           SUM(CASE WHEN us.channel = 'Catalog' THEN us.net_paid ELSE 0 END) AS catalog_paid
    FROM union_sales us
    LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY us.cust_sk
    HAVING SUM(us.net_paid) > 1000
),
ranked_customers AS (
    SELECT ca.cust_sk,
           ca.total_paid,
           ca.total_profit,
           ca.distinct_orders,
           ca.total_transactions,
           ca.first_purchase_date,
           ca.last_purchase_date,
           ca.web_paid,
           ca.store_paid,
           ca.catalog_paid,
           ROW_NUMBER() OVER (ORDER BY ca.total_profit DESC) AS profit_rank,
           RANK() OVER (PARTITION BY month(ca.last_purchase_date) ORDER BY ca.total_paid DESC) AS monthly_paid_rank,
           CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
           CASE
               WHEN ca.total_transactions = 0 THEN NULL
               ELSE ca.total_paid / NULLIF(ca.total_transactions, 0)
           END AS avg_paid_per_tx
    FROM customer_sales_agg ca
    LEFT JOIN customer c ON ca.cust_sk = c.c_customer_sk
),
customer_address_info AS (
    SELECT c.c_customer_sk AS cust_sk,
           ca.ca_city AS city,
           ca.ca_state AS state,
           ca.ca_country AS country
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
final_top AS (
    SELECT rc.profit_rank,
           rc.monthly_paid_rank,
           rc.cust_sk,
           rc.full_name,
           rc.total_paid,
           rc.total_profit,
           rc.distinct_orders,
           rc.total_transactions,
           rc.first_purchase_date,
           rc.last_purchase_date,
           rc.web_paid,
           rc.store_paid,
           rc.catalog_paid,
           rc.avg_paid_per_tx,
           ca.city,
           ca.state,
           ca.country,
           CASE
               WHEN rc.total_paid > 0 AND rc.web_paid / NULLIF(rc.total_paid, 0) > 0.5 THEN 'WebHeavy'
               WHEN rc.total_paid > 0 AND rc.store_paid / NULLIF(rc.total_paid, 0) > 0.5 THEN 'StoreHeavy'
               ELSE 'Other'
           END AS profit_source,
           (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = rc.cust_sk) AS store_return_cnt,
           (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = rc.cust_sk) AS catalog_return_cnt,
           (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = rc.cust_sk) AS web_return_cnt,
           (SELECT MAX(d2.d_date)
            FROM store_returns sr2
            JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
            WHERE sr2.sr_customer_sk = rc.cust_sk) AS latest_store_return_date
    FROM ranked_customers rc
    LEFT JOIN customer_address_info ca ON rc.cust_sk = ca.cust_sk
    WHERE rc.profit_rank <= 10
),
final_bottom AS (
    SELECT rc.profit_rank,
           rc.monthly_paid_rank,
           rc.cust_sk,
           rc.full_name,
           rc.total_paid,
           rc.total_profit,
           rc.distinct_orders,
           rc.total_transactions,
           rc.first_purchase_date,
           rc.last_purchase_date,
           rc.web_paid,
           rc.store_paid,
           rc.catalog_paid,
           rc.avg_paid_per_tx,
           ca.city,
           ca.state,
           ca.country,
           CASE
               WHEN rc.total_paid > 0 AND rc.web_paid / NULLIF(rc.total_paid, 0) > 0.5 THEN 'WebHeavy'
               WHEN rc.total_paid > 0 AND rc.store_paid / NULLIF(rc.total_paid, 0) > 0.5 THEN 'StoreHeavy'
               ELSE 'Other'
           END AS profit_source,
           (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = rc.cust_sk) AS store_return_cnt,
           (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = rc.cust_sk) AS catalog_return_cnt,
           (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = rc.cust_sk) AS web_return_cnt,
           (SELECT MAX(d2.d_date)
            FROM store_returns sr2
            JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
            WHERE sr2.sr_customer_sk = rc.cust_sk) AS latest_store_return_date
    FROM ranked_customers rc
    LEFT JOIN customer_address_info ca ON rc.cust_sk = ca.cust_sk
    WHERE rc.profit_rank >= (SELECT max(profit_rank) - 9 FROM ranked_customers)
)
SELECT *
FROM final_top
UNION ALL
SELECT *
FROM final_bottom
ORDER BY profit_rank
