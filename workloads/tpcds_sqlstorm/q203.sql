WITH sales AS (
    SELECT cs_bill_customer_sk AS cust_sk,
           cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS qty,
           cs_net_profit AS profit,
           cs_ext_discount_amt AS discount,
           'catalog' AS channel,
           cs_order_number AS order_no
    FROM catalog_sales
    UNION ALL
    SELECT ss_customer_sk AS cust_sk,
           ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS qty,
           ss_net_profit AS profit,
           ss_ext_discount_amt AS discount,
           'store' AS channel,
           ss_ticket_number AS order_no
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS cust_sk,
           ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_quantity AS qty,
           ws_net_profit AS profit,
           ws_ext_discount_amt AS discount,
           'web' AS channel,
           ws_order_number AS order_no
    FROM web_sales
), returns AS (
    SELECT cr_refunded_customer_sk AS cust_sk,
           cr_returned_date_sk AS date_sk,
           cr_return_quantity AS qty,
           cr_net_loss AS loss,
           cr_return_amt_inc_tax AS refund_amount,
           'catalog' AS channel,
           cr_order_number AS order_no
    FROM catalog_returns
    UNION ALL
    SELECT sr_customer_sk AS cust_sk,
           sr_returned_date_sk AS date_sk,
           sr_return_quantity AS qty,
           sr_net_loss AS loss,
           sr_return_amt_inc_tax AS refund_amount,
           'store' AS channel,
           sr_ticket_number AS order_no
    FROM store_returns
    UNION ALL
    SELECT wr_refunded_customer_sk AS cust_sk,
           wr_returned_date_sk AS date_sk,
           wr_return_quantity AS qty,
           wr_net_loss AS loss,
           wr_return_amt_inc_tax AS refund_amount,
           'web' AS channel,
           wr_order_number AS order_no
    FROM web_returns
), customer_sales AS (
    SELECT s.cust_sk,
           c.c_customer_id,
           CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
           d.d_year,
           SUM(s.qty) AS total_qty,
           SUM(s.profit) AS total_profit,
           SUM(s.discount) AS total_discount,
           COUNT(DISTINCT s.order_no) AS order_cnt,
           MAX(d.d_date) AS last_purchase_date,
           SUM(r.loss) AS total_loss,
           SUM(r.refund_amount) AS total_refund,
           SUM(s.profit) - COALESCE(SUM(r.loss), 0) AS net_profit,
           CASE
               WHEN SUM(s.profit) - COALESCE(SUM(r.loss), 0) > 100000 THEN 'Platinum'
               WHEN SUM(s.profit) - COALESCE(SUM(r.loss), 0) > 50000 THEN 'Gold'
               WHEN SUM(s.profit) - COALESCE(SUM(r.loss), 0) > 10000 THEN 'Silver'
               ELSE 'Bronze'
           END AS loyalty_tier,
           ROW_NUMBER() OVER (ORDER BY SUM(s.profit) - COALESCE(SUM(r.loss), 0) DESC) AS profit_rank
    FROM sales s
    LEFT JOIN returns r
           ON s.cust_sk = r.cust_sk
          AND s.date_sk = r.date_sk
          AND s.channel = r.channel
    LEFT JOIN customer c
           ON s.cust_sk = c.c_customer_sk
    LEFT JOIN date_dim d
           ON s.date_sk = d.d_date_sk
    WHERE d.d_year = 2002 OR (d.d_year = 2001 AND d.d_month_seq BETWEEN 10 AND 12)
    GROUP BY s.cust_sk, c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
), recent_activity AS (
    SELECT cs.cust_sk,
           MAX(d.d_date) AS most_recent_date
    FROM sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
    GROUP BY cs.cust_sk
)
SELECT cs.cust_sk,
       cs.c_customer_id,
       cs.full_name,
       cs.total_qty,
       cs.total_profit,
       cs.total_discount,
       cs.total_loss,
       cs.total_refund,
       cs.net_profit,
       cs.loyalty_tier,
       cs.profit_rank,
       ra.most_recent_date,
       CASE WHEN cs.net_profit > (SELECT AVG(net_profit) FROM customer_sales) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_avg,
       CONCAT('Customer_', CAST(cs.cust_sk AS VARCHAR)) AS customer_key,
       CONCAT(COALESCE(cs.loyalty_tier, 'Bronze'), '_', CAST(cs.profit_rank AS VARCHAR)) AS loyalty_rank_key,
       (SELECT COUNT(DISTINCT s2.item_sk) FROM sales s2 WHERE s2.cust_sk = cs.cust_sk) AS distinct_item_cnt,
       'Top' AS segment
FROM customer_sales cs
LEFT JOIN recent_activity ra ON cs.cust_sk = ra.cust_sk
WHERE cs.profit_rank <= 10

UNION ALL

SELECT cs.cust_sk,
       cs.c_customer_id,
       cs.full_name,
       cs.total_qty,
       cs.total_profit,
       cs.total_discount,
       cs.total_loss,
       cs.total_refund,
       cs.net_profit,
       cs.loyalty_tier,
       cs.profit_rank,
       ra.most_recent_date,
       CASE WHEN cs.net_profit > (SELECT AVG(net_profit) FROM customer_sales) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_avg,
       CONCAT('Customer_', CAST(cs.cust_sk AS VARCHAR)) AS customer_key,
       CONCAT(COALESCE(cs.loyalty_tier, 'Bronze'), '_', CAST(cs.profit_rank AS VARCHAR)) AS loyalty_rank_key,
       (SELECT COUNT(DISTINCT s2.item_sk) FROM sales s2 WHERE s2.cust_sk = cs.cust_sk) AS distinct_item_cnt,
       'Bottom' AS segment
FROM customer_sales cs
LEFT JOIN recent_activity ra ON cs.cust_sk = ra.cust_sk
WHERE cs.profit_rank > (SELECT MAX(profit_rank) - 9 FROM customer_sales)
ORDER BY profit_rank
