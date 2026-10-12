WITH combined AS (
    SELECT
        ss.ss_ticket_number AS ticket_number,
        i.i_item_id,
        i.i_category,
        p.p_promo_name,
        td.t_hour,
        ss.ss_net_profit AS net_profit,
        ROW_NUMBER() OVER (ORDER BY ss.ss_net_profit DESC) AS global_rn,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_profit DESC) AS cat_rn
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 14
    UNION ALL
    SELECT
        ws.ws_order_number AS ticket_number,
        i.i_item_id,
        i.i_category,
        p.p_promo_name,
        td.t_hour,
        ws.ws_net_profit AS net_profit,
        ROW_NUMBER() OVER (ORDER BY ws.ws_net_profit DESC) AS global_rn,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_profit DESC) AS cat_rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 14
),
category_totals AS (
    SELECT i_category,
           SUM(net_profit) AS total_profit
    FROM combined
    GROUP BY i_category
    HAVING SUM(net_profit) > 0
)
SELECT
    c.ticket_number,
    c.i_item_id,
    c.i_category,
    c.p_promo_name,
    c.t_hour,
    c.net_profit,
    c.global_rn,
    c.cat_rn
FROM combined c
JOIN category_totals ct ON c.i_category = ct.i_category
WHERE c.cat_rn <= 5
ORDER BY c.i_category, c.cat_rn
LIMIT 100
