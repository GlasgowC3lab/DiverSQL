WITH sales_customers AS (
    SELECT DISTINCT ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
catalog_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
common_customers AS (
    SELECT customer_sk FROM sales_customers
    INTERSECT
    SELECT customer_sk FROM catalog_customers
),
full_sales_returns AS (
    SELECT
        COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
        ss.ss_customer_sk,
        sr.sr_customer_sk,
        ss.ss_net_profit,
        sr.sr_net_loss
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
),
filtered AS (
    SELECT
        f.ticket_number,
        f.ss_customer_sk,
        f.sr_customer_sk,
        CASE
            WHEN f.ss_net_profit > 1000 THEN 'HIGH'
            WHEN f.ss_net_profit IS NULL THEN 'NO_SALE'
            ELSE 'LOW'
        END AS profit_category
    FROM full_sales_returns f
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = f.ticket_number
          AND sr2.sr_return_amt > 0
    )
)
SELECT DISTINCT
    cc.customer_sk,
    f.profit_category,
    f.ticket_number
FROM filtered f
JOIN common_customers cc
    ON (cc.customer_sk = f.ss_customer_sk OR cc.customer_sk = f.sr_customer_sk)
ORDER BY cc.customer_sk, f.ticket_number
