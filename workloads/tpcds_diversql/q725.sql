WITH intersect_sub AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_paid) AS total_paid,
        CASE WHEN SUM(ws.ws_quantity) > 150 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE td.t_second BETWEEN 9 AND 14
      AND i.i_manufact = 'esepriation'
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_net_paid) > 500
    INTERSECT
    SELECT
        ws2.ws_item_sk AS item_sk,
        SUM(ws2.ws_net_paid) AS total_paid,
        CASE WHEN SUM(ws2.ws_quantity) > 150 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM web_sales ws2
    JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
    WHERE i2.i_class_id = 3
    GROUP BY ws2.ws_item_sk
),
except_sub AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_paid) AS total_paid,
        CASE WHEN SUM(ws.ws_quantity) > 150 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_second IN (10, 12)
    GROUP BY ws.ws_item_sk
    EXCEPT
    SELECT
        ws3.ws_item_sk AS item_sk,
        SUM(ws3.ws_net_paid) AS total_paid,
        CASE WHEN SUM(ws3.ws_quantity) > 150 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM web_sales ws3
    JOIN item i3 ON ws3.ws_item_sk = i3.i_item_sk
    WHERE i3.i_category = 'Electronics'
    GROUP BY ws3.ws_item_sk
)
SELECT
    sub.item_sk,
    sub.total_paid,
    sub.volume_category,
    (
        SELECT SUM(ws_inner.ws_wholesale_cost)
        FROM web_sales ws_inner
        WHERE ws_inner.ws_item_sk = sub.item_sk
    ) AS total_wholesale,
    'INTERSECT' AS source_flag
FROM intersect_sub sub
WHERE EXISTS (
    SELECT 1
    FROM item it
    WHERE it.i_item_sk = sub.item_sk
      AND it.i_color = 'Red'
)
UNION ALL
SELECT
    sub.item_sk,
    sub.total_paid,
    sub.volume_category,
    (
        SELECT SUM(ws_inner.ws_wholesale_cost)
        FROM web_sales ws_inner
        WHERE ws_inner.ws_item_sk = sub.item_sk
    ) AS total_wholesale,
    'EXCEPT' AS source_flag
FROM except_sub sub
WHERE EXISTS (
    SELECT 1
    FROM item it
    WHERE it.i_item_sk = sub.item_sk
      AND it.i_color = 'Red'
)
ORDER BY total_paid DESC
LIMIT 100
