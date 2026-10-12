WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        i.i_product_name,
        sm.sm_type,
        w.w_state,
        wp.wp_url,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
        AND wp.wp_url LIKE 'http%://www.example.com/%'
    GROUP BY
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        i.i_product_name,
        sm.sm_type,
        w.w_state,
        wp.wp_url
),
prepared AS (
    SELECT
        i_item_sk,
        i_brand,
        i_category,
        i_item_desc,
        i_product_name,
        sm_type,
        w_state,
        wp_url,
        total_sales,
        avg_profit,
        order_cnt,
        concat(i_brand, '-', i_category) AS brand_category
    FROM sales_agg
)
SELECT
    concat(p.brand_category, ':', p.sm_type) AS brand_mode,
    p.w_state,
    p.total_sales,
    p.avg_profit,
    p.order_cnt,
    regexp_extract(p.i_product_name, '(\\w+)-\\d+', 1) AS product_prefix,
    substring(p.i_item_desc FROM 1 FOR 15) AS short_desc
FROM prepared p
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = p.i_item_sk
      AND inv.inv_quantity_on_hand > 500
)
ORDER BY p.total_sales DESC
LIMIT 100
