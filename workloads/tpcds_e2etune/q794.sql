WITH item_daily AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ss.ss_quantity) AS total_sales_qty,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM catalog_returns cr
    INNER JOIN store_sales ss
        ON cr.cr_item_sk = ss.ss_item_sk
       AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
    WHERE cr.cr_return_quantity > 10
      AND ss.ss_quantity > 0
      AND cr.cr_returned_date_sk BETWEEN 2451016 AND 2451118
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
    HAVING SUM(cr.cr_return_quantity) > 20
)
SELECT
    item_daily.cr_item_sk,
    item_daily.date_sk,
    item_daily.total_return_qty,
    item_daily.total_return_amount,
    item_daily.total_sales_qty,
    item_daily.total_sales_amount,
    item_daily.total_net_profit,
    CASE 
        WHEN item_daily.total_sales_amount = 0 THEN 0
        ELSE item_daily.total_return_amount / item_daily.total_sales_amount
    END AS return_to_sales_ratio,
    RANK() OVER (PARTITION BY item_daily.date_sk 
                 ORDER BY 
                 CASE 
                     WHEN item_daily.total_sales_amount = 0 THEN 0
                     ELSE item_daily.total_return_amount / item_daily.total_sales_amount
                 END DESC) AS daily_rank
FROM item_daily
WHERE 
    CASE 
        WHEN item_daily.total_sales_amount = 0 THEN 0
        ELSE item_daily.total_return_amount / item_daily.total_sales_amount
    END > 0.05
ORDER BY return_to_sales_ratio DESC
LIMIT 100
