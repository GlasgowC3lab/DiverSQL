/* goal: Identify customers and items sold via catalog sales in 2001 that were never returned in store returns, and label each sale as High or Low profit based on net profit */
WITH purchase_set AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
    EXCEPT
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        CAST(NULL AS decimal(7,2)) AS net_profit,
        sr.sr_returned_date_sk AS sold_date_sk
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    d.d_date,
    CASE WHEN p.net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
FROM purchase_set p
JOIN customer c ON p.customer_sk = c.c_customer_sk
JOIN item i ON p.item_sk = i.i_item_sk
JOIN date_dim d ON p.sold_date_sk = d.d_date_sk
ORDER BY c.c_customer_id, i.i_item_id
LIMIT 100
