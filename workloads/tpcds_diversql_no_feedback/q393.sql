/*
Goal: Identify the top‑5 selling items during business hours (09:00‑17:00) for each sales channel (store and web) and compare them side‑by‑side.
The query aggregates sales per item and hour for store_sales and web_sales, unions the two result sets, ranks items within each channel by total sales, and returns the highest‑ranking rows ordered by channel and sales amount.
*/
WITH store_agg AS (
    SELECT
        'store' AS channel,
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        td.t_hour
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ss.ss_ext_sales_price > 100
    GROUP BY i.i_item_id, i.i_item_desc, td.t_hour
),
web_agg AS (
    SELECT
        'web' AS channel,
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        td.t_hour
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_sales_price > 100
    GROUP BY i.i_item_id, i.i_item_desc, td.t_hour
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
),
ranked AS (
    SELECT
        channel,
        i_item_id,
        i_item_desc,
        total_sales,
        t_hour,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS rn
    FROM combined
)
SELECT
    channel,
    i_item_id,
    i_item_desc,
    total_sales,
    t_hour
FROM ranked
WHERE rn <= 5
ORDER BY channel, total_sales DESC
LIMIT 100
