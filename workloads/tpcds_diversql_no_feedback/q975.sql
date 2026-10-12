WITH avg_profit AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
),
high_profit_sales AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_profit > (SELECT avg_profit FROM avg_profit)
),
returned_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity > 0
),
target_orders AS (
    SELECT cs_order_number
    FROM high_profit_sales
    EXCEPT
    SELECT cr_order_number
    FROM returned_orders
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    td.t_hour,
    td.t_minute,
    inv.inv_quantity_on_hand,
    ws.ws_net_profit,
    CASE
        WHEN cs.cs_net_profit > 1000 THEN 'High'
        WHEN cs.cs_net_profit > 0   THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY cs.cs_net_paid DESC) AS brand_sales_rank
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = td.t_time_sk
JOIN (
    SELECT inv_item_sk,
           inv_quantity_on_hand
    FROM inventory
) inv
    ON inv.inv_item_sk = i.i_item_sk
WHERE i.i_rec_end_date >= DATE '2001-01-01'
  AND i.i_units = 'Ounce'
  AND cp.cp_department = 'Books'
  AND td.t_shift = 'first'
  AND cs.cs_quantity > 2
  AND ws.ws_net_profit > 0
  AND inv.inv_quantity_on_hand > 5
  AND cs.cs_order_number IN (SELECT cs_order_number FROM target_orders)
ORDER BY i.i_brand, brand_sales_rank
