WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_ship_date_sk,
        ws_warehouse_sk,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk, ws_sold_date_sk, ws_sold_time_sk, ws_ship_date_sk, ws_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    i_sales.i_category,
    d_sold.d_year,
    SUM(ws_agg.total_qty) AS sum_quantity,
    SUM(ws_agg.total_sales) AS sum_sales,
    SUM(ws_agg.total_profit) AS sum_profit,
    COUNT(DISTINCT ws_agg.ws_order_number) AS order_cnt,
    CASE
        WHEN SUM(ws_agg.total_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag
FROM ws_agg
JOIN date_dim d_sold
    ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws_agg.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN item i_sales
    ON ws_agg.ws_item_sk = i_sales.i_item_sk
JOIN item i_promo
    ON ws_agg.ws_item_sk = i_promo.i_item_sk
JOIN promotion p
    ON i_promo.i_item_sk = p.p_item_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_item_sk = ws_agg.ws_item_sk
      AND p2.p_discount_active = 'Y'
)
GROUP BY ROLLUP (w.w_warehouse_name, i_sales.i_category, d_sold.d_year)
ORDER BY w.w_warehouse_name NULLS FIRST, i_sales.i_category NULLS FIRST, d_sold.d_year NULLS FIRST
LIMIT 100
