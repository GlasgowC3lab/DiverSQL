WITH cs AS (
    SELECT
        cs_item_sk AS item_sk,
        cs_net_profit AS net_profit,
        cs_quantity AS quantity,
        cs_ext_discount_amt AS discount_amt,
        cs_promo_sk AS promo_sk,
        'catalog' AS channel
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450820 AND 2450825
),
ss AS (
    SELECT
        ss_item_sk AS item_sk,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity,
        ss_ext_discount_amt AS discount_amt,
        ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450820 AND 2450825
),
ws AS (
    SELECT
        ws_item_sk AS item_sk,
        ws_net_profit AS net_profit,
        ws_quantity AS quantity,
        ws_ext_discount_amt AS discount_amt,
        ws_promo_sk AS promo_sk,
        'web' AS channel
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450820 AND 2450825
),
sales_union AS (
    SELECT * FROM cs
    UNION ALL
    SELECT * FROM ss
    UNION ALL
    SELECT * FROM ws
),
inventory_latest AS (
    SELECT
        inv_item_sk,
        inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450825
)
SELECT
    i.i_brand,
    i.i_color,
    SUM(su.net_profit) AS total_net_profit,
    SUM(su.quantity) AS total_quantity_sold,
    SUM(su.discount_amt) / NULLIF(SUM(su.quantity), 0) AS avg_discount_per_unit,
    SUM(il.inv_quantity_on_hand) AS total_inventory_on_hand,
    RANK() OVER (ORDER BY SUM(su.net_profit) DESC) AS profit_rank
FROM sales_union su
JOIN item i ON su.item_sk = i.i_item_sk
LEFT JOIN inventory_latest il ON i.i_item_sk = il.inv_item_sk
GROUP BY i.i_brand, i.i_color
HAVING SUM(su.net_profit) > 0
ORDER BY profit_rank
LIMIT 10
