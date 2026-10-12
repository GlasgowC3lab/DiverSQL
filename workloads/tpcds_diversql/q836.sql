WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
store_order_keys AS (
    SELECT ss_ticket_number AS order_id
    FROM store_sales
    WHERE ss_quantity > 0
),
web_order_keys AS (
    SELECT ws_order_number AS order_id
    FROM web_sales
    WHERE ws_quantity > 0
),
missing_web_orders AS (
    SELECT order_id
    FROM store_order_keys
    EXCEPT
    SELECT order_id
    FROM web_order_keys
),
full_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity
    FROM store_sales ss
    FULL OUTER JOIN web_sales ws
        ON ss.ss_ticket_number = ws.ws_order_number
),
joined_all AS (
    SELECT
        i.i_category,
        p_cs.p_promo_name,
        sm.sm_type,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank,
        CASE WHEN mo.order_id IS NOT NULL THEN 1 ELSE 0 END AS missing_web_flag
    FROM item i
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN missing_web_orders mo ON cs.cs_order_number = mo.order_id
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs.cs_ext_sales_price > 1000
      AND p_cs.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
)
SELECT
    i_category,
    p_promo_name,
    sm_type,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    MIN(inv_quantity_on_hand) AS min_stock,
    MAX(sales_rank) AS max_rank,
    SUM(missing_web_flag) AS missing_web_orders
FROM joined_all
GROUP BY i_category, p_promo_name, sm_type
ORDER BY total_sales DESC
LIMIT 100
