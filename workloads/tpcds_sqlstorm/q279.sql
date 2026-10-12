WITH sales_union AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_order_number AS order_no,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_customer_sk AS cust_sk,
           ss.ss_ticket_number AS order_no,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_order_number AS order_no,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           'web' AS sales_channel
    FROM web_sales ws
),
returns_union AS (
    SELECT sr.sr_customer_sk AS cust_sk,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_net_loss AS net_loss,
           'store' AS return_channel,
           sr.sr_ticket_number AS order_no
    FROM store_returns sr
    UNION ALL
    SELECT cr.cr_returning_customer_sk AS cust_sk,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_net_loss AS net_loss,
           'catalog' AS return_channel,
           cr.cr_order_number AS order_no
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_returning_customer_sk AS cust_sk,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_net_loss AS net_loss,
           'web' AS return_channel,
           wr.wr_order_number AS order_no
    FROM web_returns wr
),
sales_customers AS (
    SELECT DISTINCT cust_sk
    FROM sales_union
),
returns_customers AS (
    SELECT DISTINCT cust_sk
    FROM returns_union
),
customers_without_returns AS (
    SELECT cust_sk
    FROM sales_customers
    EXCEPT
    SELECT cust_sk
    FROM returns_customers
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.net_paid) AS total_net_paid,
        COUNT(DISTINCT s.order_no) AS distinct_orders,
        COUNT(DISTINCT s.item_sk) AS distinct_items,
        SUM(CASE WHEN s.sales_channel = 'store' THEN 1 ELSE 0 END) AS store_orders,
        SUM(CASE WHEN s.sales_channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_orders,
        SUM(CASE WHEN s.sales_channel = 'web' THEN 1 ELSE 0 END) AS web_orders
    FROM customer c
    LEFT JOIN sales_union s ON c.c_customer_sk = s.cust_sk
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        d.d_month_seq,
        d.d_moy
),
customer_returns AS (
    SELECT
        c.c_customer_sk,
        SUM(r.net_loss) AS total_net_loss,
        COUNT(DISTINCT r.order_no) AS distinct_return_orders
    FROM customer c
    LEFT JOIN returns_union r ON c.c_customer_sk = r.cust_sk
    GROUP BY c.c_customer_sk
),
customer_summary AS (
    SELECT
        cs.c_customer_sk,
        cs.full_name,
        cs.c_last_name,
        cs.d_year,
        cs.d_month_seq,
        cs.d_moy,
        cs.total_net_profit,
        cs.total_net_paid,
        COALESCE(cr.total_net_loss, 0) AS total_net_loss,
        cs.total_net_profit - COALESCE(cr.total_net_loss, 0) AS net_profit_after_returns,
        cs.distinct_orders,
        cs.distinct_items,
        cs.store_orders,
        cs.catalog_orders,
        cs.web_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_net_profit DESC) AS profit_rank,
        AVG(cs.total_net_profit) OVER (PARTITION BY cs.d_year) AS avg_yearly_profit,
        SUM(cs.total_net_profit) OVER (PARTITION BY cs.d_year) AS yearly_total_profit,
        CONCAT('Cust_', LPAD(CAST(cs.c_customer_sk AS VARCHAR), 6, '0')) AS cust_code,
        CASE
            WHEN cs.total_net_profit > 100000 THEN 'Platinum'
            WHEN cs.total_net_profit > 50000 THEN 'Gold'
            WHEN cs.total_net_profit > 10000 THEN 'Silver'
            ELSE 'Bronze'
        END AS profit_class
    FROM customer_sales cs
    LEFT JOIN customer_returns cr ON cs.c_customer_sk = cr.c_customer_sk
),
customer_item_category AS (
    SELECT
        su.cust_sk AS c_customer_sk,
        i.i_category,
        AVG(su.net_profit) AS avg_profit_per_category
    FROM sales_union su
    JOIN item i ON su.item_sk = i.i_item_sk
    GROUP BY su.cust_sk, i.i_category
),
final AS (
    SELECT
        cs.c_customer_sk,
        cs.full_name,
        cs.c_last_name,
        cs.cust_code,
        cs.profit_class,
        cs.profit_rank,
        cs.total_net_profit,
        cs.total_net_loss,
        cs.net_profit_after_returns,
        cs.avg_yearly_profit,
        cs.yearly_total_profit,
        cs.store_orders,
        cs.catalog_orders,
        cs.web_orders,
        CONCAT(SUBSTR(cs.full_name, 1, 1), '.', cs.c_last_name) AS name_abbrev,
        LOWER(cs.full_name) AS full_name_lower,
        COALESCE(ic.avg_profit_across_categories, 0) AS avg_profit_per_category,
        (SELECT MAX(avg_profit_per_category) FROM customer_item_category ci2 WHERE ci2.c_customer_sk = cs.c_customer_sk) AS max_avg_profit_category,
        (
            SELECT COALESCE(SUM(r2.net_loss), 0)
            FROM returns_union r2
            JOIN date_dim d2 ON r2.date_sk = d2.d_date_sk
            WHERE r2.cust_sk = cs.c_customer_sk
              AND d2.d_year = cs.d_year
              AND d2.d_month_seq = cs.d_month_seq
        ) AS month_return_loss,
        CASE
            WHEN cuwr.cust_sk IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS has_sales_no_returns
    FROM customer_summary cs
    LEFT JOIN (
        SELECT c_customer_sk, AVG(avg_profit_per_category) AS avg_profit_across_categories
        FROM customer_item_category
        GROUP BY c_customer_sk
    ) ic ON cs.c_customer_sk = ic.c_customer_sk
    LEFT JOIN customers_without_returns cuwr ON cs.c_customer_sk = cuwr.cust_sk
    WHERE cs.net_profit_after_returns IS NOT NULL
)
SELECT *
FROM final
WHERE profit_rank <= 10
ORDER BY net_profit_after_returns DESC
