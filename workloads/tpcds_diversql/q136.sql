WITH avg_floor AS (
    SELECT AVG(s_floor_space) AS avg_fs FROM store
)
SELECT
    store.s_store_id,
    store.s_store_name,
    store.s_market_manager,
    store.s_floor_space,
    date_dim.d_date,
    date_dim.d_quarter_name,
    date_dim.d_year,
    CASE WHEN store.s_floor_space > 8000000 THEN 'Large' ELSE 'Medium' END AS store_size_category,
    ROW_NUMBER() OVER (ORDER BY store.s_store_id) AS global_row_num,
    RANK() OVER (PARTITION BY date_dim.d_quarter_name ORDER BY store.s_floor_space DESC) AS floor_space_rank
FROM
    store
FULL OUTER JOIN
    date_dim
ON store.s_closed_date_sk = date_dim.d_date_sk
WHERE
    date_dim.d_quarter_name = '1901Q4'
    AND date_dim.d_year = 1901
    AND date_dim.d_weekend = 'N'
    AND store.s_market_manager IN ('Thomas Benton', 'Roger Nichols')
    AND store.s_floor_space > (SELECT avg_fs FROM avg_floor)
    AND store.s_floor_space > 6000000
ORDER BY
    global_row_num
LIMIT 100
