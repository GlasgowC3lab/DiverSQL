/* goal: Calculate total inventory quantity and distinct items for each combination of date and concatenated day‑name and month, restricted to weekend days that match specific holiday patterns, using string functions and a sampled inventory table. */
WITH inv_sample AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_date,
    concat(d.d_day_name, '_', d.d_current_month) AS day_month,
    regexp_extract(d.d_holiday, '(\\w+)', 1) AS holiday_word,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_item_count
FROM inv_sample i
JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
WHERE
    regexp_like(d.d_day_name, '^S')               -- days starting with S (Saturday, Sunday)
    AND d.d_holiday LIKE '%Day%'                  -- holidays containing the word "Day"
    AND d.d_current_week LIKE 'Y%'                -- current week indicator starts with 'Y'
GROUP BY
    d.d_date,
    concat(d.d_day_name, '_', d.d_current_month),
    regexp_extract(d.d_holiday, '(\\w+)', 1)
ORDER BY total_quantity_on_hand DESC
LIMIT 100
