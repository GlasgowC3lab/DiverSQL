WITH store_combined AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_net_loss AS return_loss,
        ws.ws_net_profit AS sales_profit,
        ws.ws_net_paid AS sales_paid
    FROM store_returns sr
    JOIN web_sales ws
        ON sr.sr_customer_sk = ws.ws_bill_customer_sk
        AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
)
SELECT
    sc.store_sk,
    COUNT(DISTINCT sc.customer_sk) AS unique_customers,
    SUM(sc.return_loss) AS total_return_loss,
    SUM(sc.sales_profit) AS total_sales_profit,
    SUM(sc.sales_paid) AS total_sales_paid,
    CASE
        WHEN SUM(sc.return_loss) > 10000 THEN 'High Loss'
        WHEN SUM(sc.return_loss) > 5000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    DENSE_RANK() OVER (ORDER BY SUM(sc.return_loss) DESC) AS loss_rank,
    ROUND((SUM(sc.return_loss) / NULLIF(SUM(sc.sales_paid), 0)) * 100, 2) AS loss_pct_of_sales
FROM store_combined sc
GROUP BY sc.store_sk
HAVING SUM(sc.sales_paid) > 0
ORDER BY loss_rank
