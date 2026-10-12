WITH filtered_store AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_time_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_ship_cost,
        r.r_reason_desc,
        r.r_reason_id,
        td.t_meal_time,
        td.t_am_pm,
        CONCAT(r.r_reason_desc, ' - ', td.t_meal_time) AS reason_meal,
        CASE WHEN regexp_like(r.r_reason_desc, '(?i)^(.*\b(not|lost|unauthoized)\b.*)$') THEN 1 ELSE 0 END AS reason_flag
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE r.r_reason_id LIKE 'AAAAAAAAA%'
      AND td.t_meal_time LIKE '%breakfast%'
),
full_outer AS (
    SELECT
        fs.sr_item_sk,
        fs.sr_return_amt_inc_tax,
        fs.reason_meal,
        td.t_meal_time,
        td.t_am_pm,
        fs.sr_return_time_sk
    FROM filtered_store fs
    FULL OUTER JOIN time_dim td
        ON fs.sr_return_time_sk = td.t_time_sk
    WHERE fs.sr_return_amt_inc_tax > (
        SELECT MAX(cr_return_amount) FROM catalog_returns
    )
)
SELECT
    fo.reason_meal,
    fo.t_meal_time,
    SUM(fo.sr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(*) AS cnt_returns
FROM full_outer fo
WHERE fo.sr_item_sk IN (
    SELECT sr_item_sk FROM store_returns
    INTERSECT
    SELECT cr_item_sk FROM catalog_returns
)
GROUP BY GROUPING SETS (
    (reason_meal, t_meal_time),
    (t_meal_time)
)
ORDER BY total_return_inc_tax DESC
LIMIT 100
