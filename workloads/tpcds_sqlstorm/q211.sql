WITH
d AS (
    SELECT d_date_sk,
           d_year,
           d_holiday,
           d_date
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
      AND (d_holiday = 'Y' OR d_holiday IS NULL)
),
sales_combined AS (
    SELECT
        COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS sold_date_sk,
        COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
        COALESCE(cs.cs_order_number, ss.ss_ticket_number, ws.ws_order_number) AS order_number,
        COALESCE(cs.cs_bill_customer_sk, ss.ss_customer_sk, ws.ws_bill_customer_sk) AS customer_sk,
        SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_profit,
        SUM(COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    FULL OUTER JOIN store_sales ss
        ON cs.cs_sold_date_sk = ss.ss_sold_date_sk
       AND cs.cs_item_sk = ss.ss_item_sk
    FULL OUTER JOIN web_sales ws
        ON COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk) = ws.ws_sold_date_sk
       AND COALESCE(cs.cs_item_sk, ss.ss_item_sk) = ws.ws_item_sk
    GROUP BY 1,2,3,4
),
customer_sales AS (
    SELECT
        s.customer_sk,
        d.d_year,
        SUM(s.total_profit) AS profit,
        SUM(s.total_sales) AS sales,
        SUM(s.txn_count) AS transactions
    FROM sales_combined s
    JOIN d ON s.sold_date_sk = d.d_date_sk
    GROUP BY s.customer_sk, d.d_year
),
customer_rank AS (
    SELECT
        customer_sk,
        d_year,
        profit,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY profit DESC NULLS LAST) AS rn,
        AVG(profit) OVER (PARTITION BY d_year) AS avg_profit_year
    FROM customer_sales
),
top_customers AS (
    SELECT customer_sk, d_year, profit
    FROM customer_rank
    WHERE rn <= 3
),
customer_returns AS (
    SELECT
        c.c_customer_sk,
        d.d_year,
        (SELECT SUM(COALESCE(sr.sr_net_loss,0))
         FROM store_returns sr
         JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
         WHERE sr.sr_customer_sk = c.c_customer_sk
           AND d2.d_year = d.d_year) AS store_loss,
        (SELECT SUM(COALESCE(cr.cr_net_loss,0))
         FROM catalog_returns cr
         JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
         WHERE cr.cr_returning_customer_sk = c.c_customer_sk
           AND d2.d_year = d.d_year) AS catalog_loss,
        (SELECT SUM(COALESCE(wr.wr_net_loss,0))
         FROM web_returns wr
         JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
         WHERE wr.wr_returning_customer_sk = c.c_customer_sk
           AND d2.d_year = d.d_year) AS web_loss,
        (SELECT COUNT(*)
         FROM store_returns sr
         JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
         WHERE sr.sr_customer_sk = c.c_customer_sk
           AND d2.d_year = d.d_year) AS store_return_cnt,
        (SELECT COUNT(*)
         FROM catalog_returns cr
         JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
         WHERE cr.cr_returning_customer_sk = c.c_customer_sk
           AND d2.d_year = d.d_year) AS catalog_return_cnt,
        (SELECT COUNT(*)
         FROM web_returns wr
         JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
         WHERE wr.wr_returning_customer_sk = c.c_customer_sk
           AND d2.d_year = d.d_year) AS web_return_cnt
    FROM customer c
    CROSS JOIN d
    WHERE c.c_customer_sk IS NOT NULL
),
final_data AS (
    SELECT
        tc.d_year,
        tc.customer_sk,
        COALESCE(c.c_first_name, 'UNKNOWN') || ' ' || COALESCE(c.c_last_name, 'UNKNOWN') AS full_name,
        tc.profit,
        cs.sales,
        cs.transactions,
        CASE WHEN cs.transactions = 0 THEN NULL ELSE cs.sales / cs.transactions END AS avg_sale_per_tx,
        COALESCE(cr.store_loss,0) + COALESCE(cr.catalog_loss,0) + COALESCE(cr.web_loss,0) AS total_loss,
        COALESCE(cr.store_return_cnt,0) + COALESCE(cr.catalog_return_cnt,0) + COALESCE(cr.web_return_cnt,0) AS total_returns,
        CASE 
            WHEN (COALESCE(cr.store_return_cnt,0) + COALESCE(cr.catalog_return_cnt,0) + COALESCE(cr.web_return_cnt,0)) = 0 THEN NULL
            ELSE (COALESCE(cr.store_loss,0) + COALESCE(cr.catalog_loss,0) + COALESCE(cr.web_loss,0))
                 / NULLIF((COALESCE(cr.store_return_cnt,0) + COALESCE(cr.catalog_return_cnt,0) + COALESCE(cr.web_return_cnt,0)),0)
        END AS avg_loss_per_return,
        CASE 
            WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
            WHEN c.c_preferred_cust_flag = 'N' THEN 'Standard'
            ELSE 'UNKNOWN'
        END AS pref_status,
        ROW_NUMBER() OVER (PARTITION BY tc.d_year ORDER BY tc.profit DESC) AS rank_in_year
    FROM top_customers tc
    LEFT JOIN customer c ON c.c_customer_sk = tc.customer_sk
    LEFT JOIN customer_sales cs ON cs.customer_sk = tc.customer_sk AND cs.d_year = tc.d_year
    LEFT JOIN customer_returns cr ON cr.c_customer_sk = tc.customer_sk AND cr.d_year = tc.d_year
    WHERE (tc.d_year % 2 = 1 
          OR EXISTS (SELECT 1 FROM d d_h WHERE d_h.d_year = tc.d_year AND d_h.d_holiday = 'Y'))
      AND (c.c_birth_country = 'United States' OR c.c_birth_country IS NULL)
      AND (c.c_email_address IS NULL OR REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'))
      AND (c.c_preferred_cust_flag IS NOT NULL)
)

SELECT
    d_year,
    customer_sk,
    full_name,
    profit,
    sales,
    transactions,
    avg_sale_per_tx,
    total_loss,
    total_returns,
    avg_loss_per_return,
    pref_status,
    rank_in_year
FROM final_data
WHERE rank_in_year = 1

UNION ALL

SELECT
    -1 AS d_year,
    NULL AS customer_sk,
    'TOTAL' AS full_name,
    SUM(profit) AS profit,
    SUM(sales) AS sales,
    SUM(transactions) AS transactions,
    CASE WHEN SUM(transactions) = 0 THEN NULL ELSE SUM(sales) / SUM(transactions) END AS avg_sale_per_tx,
    SUM(total_loss) AS total_loss,
    SUM(total_returns) AS total_returns,
    CASE WHEN SUM(total_returns) = 0 THEN NULL ELSE SUM(total_loss) / SUM(total_returns) END AS avg_loss_per_return,
    NULL AS pref_status,
    NULL AS rank_in_year
FROM final_data
WHERE rank_in_year = 1
