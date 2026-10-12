WITH key_diff AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT ws_order_number FROM web_sales
    ),
    filtered_time AS (
        SELECT td.t_time_sk,
               td.t_time_id,
               td.t_meal_time,
               td.t_minute,
               CONCAT('Time ', td.t_time_id) AS time_label,
               regexp_extract(td.t_time_id, 'A{5}(.{1})', 1) AS extracted_char,
               CASE WHEN regexp_like(td.t_time_id, '^AAAAA') THEN true ELSE false END AS starts_with_AAAAA
        FROM time_dim td
        WHERE td.t_meal_time LIKE 'dinner%'
          AND NOT EXISTS (
                SELECT 1 FROM web_returns wr
                WHERE wr.wr_returned_time_sk = td.t_time_sk
          )
    )
SELECT
    ft.time_label,
    ft.t_time_id,
    ft.extracted_char,
    ft.starts_with_AAAAA,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    (
        SELECT SUM(cs.cs_net_profit)
        FROM catalog_sales cs
        WHERE cs.cs_sold_time_sk = ft.t_time_sk
    ) AS total_profit_for_time,
    (
        SELECT COUNT(DISTINCT kd.cs_order_number)
        FROM key_diff kd
    ) AS total_key_diff_count
FROM store_returns sr
FULL OUTER JOIN filtered_time ft
    ON sr.sr_return_time_sk = ft.t_time_sk
WHERE sr.sr_return_quantity IS NOT NULL
ORDER BY total_profit_for_time DESC
LIMIT 100
