WITH sampled_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IS NOT NULL
),
full_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_sold_time_sk,
        p.p_promo_name,
        p.p_discount_active
    FROM sampled_sales ws
    FULL OUTER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT
    q.ws_order_number,
    q.ws_net_profit,
    q.p_promo_name,
    q.sm_carrier,
    q.t_hour,
    q.w_warehouse_name,
    q.avg_warehouse_profit
FROM (
    SELECT
        fj.ws_order_number,
        fj.ws_net_profit,
        fj.p_promo_name,
        sm.sm_carrier,
        t.t_hour,
        w.w_warehouse_name,
        (SELECT avg(ws3.ws_net_profit)
         FROM web_sales ws3
         WHERE ws3.ws_warehouse_sk = fj.ws_warehouse_sk) AS avg_warehouse_profit
    FROM full_join fj
    JOIN ship_mode sm ON fj.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON fj.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON fj.ws_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_am_pm = 'PM'
      AND sm.sm_carrier = 'FEDEX'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = fj.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    UNION
    SELECT
        fj.ws_order_number,
        fj.ws_net_profit,
        fj.p_promo_name,
        sm.sm_carrier,
        t.t_hour,
        w.w_warehouse_name,
        (SELECT avg(ws3.ws_net_profit)
         FROM web_sales ws3
         WHERE ws3.ws_warehouse_sk = fj.ws_warehouse_sk) AS avg_warehouse_profit
    FROM full_join fj
    JOIN ship_mode sm ON fj.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON fj.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON fj.ws_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_am_pm = 'AM'
      AND sm.sm_carrier = 'DHL'
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = fj.ws_ship_mode_sk
            AND sm2.sm_type = 'OVERNIGHT'
      )
) AS q
ORDER BY q.ws_net_profit DESC
LIMIT 100
