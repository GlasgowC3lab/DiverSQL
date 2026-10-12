WITH sales_union AS (
    -- Store channel sales for large items with inventory in stock
    SELECT
        'store' AS channel,
        i.i_category,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_size = 'large'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    UNION ALL
    -- Web channel sales for large items with inventory in stock
    SELECT
        'web' AS channel,
        i.i_category,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE i.i_size = 'large'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
)
SELECT
    channel,
    i_category,
    SUM(sales_amount) AS total_sales,
    SUM(profit_amount) AS total_profit
FROM sales_union
GROUP BY ROLLUP (channel, i_category)
ORDER BY
    CASE WHEN channel IS NULL THEN 2 ELSE 1 END,
    channel,
    i_category
LIMIT 100
