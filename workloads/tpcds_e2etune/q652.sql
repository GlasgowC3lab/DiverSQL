SELECT
    category,
    brand,
    order_cnt,
    total_qty,
    total_sales,
    total_profit,
    avg_discount,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_manager_id IN (6, 98, 18)
      AND i.i_size = 'large'
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_product_name LIKE '%able%'
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(ws.ws_ext_sales_price) > 1000
) sub
ORDER BY profit_rank
LIMIT 20
