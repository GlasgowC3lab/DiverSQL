WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_ship_addr_sk IN (4286648, 5146341)
      AND ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_quantity BETWEEN 1 AND 5
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = ws.ws_item_sk
            AND ws2.ws_sold_time_sk = ws.ws_sold_time_sk
            AND ws2.ws_quantity > 10
      )
),
brand_factor AS (
    SELECT i.i_brand, i.i_manager_id
    FROM item i
    WHERE i.i_manager_id IN (19, 44)
    GROUP BY i.i_brand, i.i_manager_id
),
time_filter AS (
    SELECT t.t_time_sk, t.t_am_pm, t.t_hour, t.t_minute
    FROM time_dim t
    WHERE t.t_am_pm = 'PM' AND t.t_hour BETWEEN 12 AND 18
)
SELECT
    b.i_brand,
    b.i_manager_id,
    tf.t_am_pm,
    tf.t_hour,
    SUM(fs.ws_quantity) AS total_quantity,
    AVG(fs.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    COUNT(DISTINCT fs.ws_sold_date_sk) AS sales_days,
    MIN(fs.ws_net_profit) AS min_profit,
    MAX(fs.ws_net_profit) AS max_profit
FROM filtered_sales fs
JOIN item i ON fs.ws_item_sk = i.i_item_sk
JOIN time_dim tf ON fs.ws_sold_time_sk = tf.t_time_sk
CROSS JOIN (VALUES (1), (2)) AS v(multiplier)
JOIN brand_factor b ON i.i_brand = b.i_brand
WHERE v.multiplier = 1
GROUP BY b.i_brand, b.i_manager_id, tf.t_am_pm, tf.t_hour
ORDER BY total_quantity DESC
LIMIT 100
