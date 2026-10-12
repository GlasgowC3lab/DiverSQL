WITH
    sampled_ws AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    order_excluded AS (
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_quantity > 10
        EXCEPT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_quantity < 5
    ),
    full_promo AS (
        SELECT
            ws.ws_order_number,
            ws.ws_warehouse_sk,
            ws.ws_ship_mode_sk,
            ws.ws_promo_sk,
            ws.ws_bill_hdemo_sk,
            ws.ws_net_profit,
            ws.ws_quantity,
            ws.ws_sold_date_sk,
            p.p_cost,
            p.p_promo_name
        FROM sampled_ws ws
        FULL OUTER JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
    )
SELECT
    fp.ws_order_number,
    w.w_warehouse_name,
    sm.sm_type,
    hd.hd_buy_potential,
    fp.p_promo_name,
    fp.ws_quantity,
    fp.ws_net_profit,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY fp.ws_net_profit DESC) AS profit_rank_by_warehouse,
    CASE
        WHEN hd.hd_vehicle_count > 2 THEN 'High Vehicle'
        WHEN hd.hd_vehicle_count = 0 THEN 'No Vehicle'
        ELSE 'Low Vehicle'
    END AS vehicle_category
FROM full_promo fp
LEFT JOIN warehouse w
    ON fp.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
    ON fp.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN household_demographics hd
    ON fp.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
    AND fp.p_cost > 500
    AND hd.hd_vehicle_count >= 0
    AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
    AND fp.ws_order_number IN (SELECT ws_order_number FROM order_excluded)
ORDER BY w.w_warehouse_name, profit_rank_by_warehouse
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY
