WITH filtered_returns AS (
  SELECT
    wr.wr_returned_time_sk,
    wr.wr_returned_date_sk,
    wr.wr_web_page_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    td.t_meal_time,
    td.t_hour,
    td.t_minute,
    wp.wp_type,
    wp.wp_url,
    wp.wp_autogen_flag,
    wp.wp_char_count
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE td.t_meal_time IN ('breakfast', 'lunch')
    AND td.t_minute BETWEEN 5 AND 20
    AND wp.wp_autogen_flag = 'N'
    AND wp.wp_char_count > 2000
    AND wr.wr_return_quantity >= 1
),

lateral_calc AS (
  SELECT
    fr.*, 
    lc.minute_of_day
  FROM filtered_returns fr
  CROSS JOIN LATERAL (
    SELECT fr.t_hour * 60 + fr.t_minute AS minute_of_day
  ) AS lc
),

cube_agg AS (
  SELECT
    COALESCE(wp_type, 'ALL') AS wp_type,
    COALESCE(t_meal_time, 'ALL') AS t_meal_time,
    SUM(wr_return_amt) AS total_return_amt,
    AVG(wr_return_tax) AS avg_return_tax,
    COUNT(*) AS cnt_returns,
    MIN(minute_of_day) AS min_minute_of_day,
    MAX(minute_of_day) AS max_minute_of_day
  FROM lateral_calc
  GROUP BY CUBE(wp_type, t_meal_time)
),

union_agg AS (
  SELECT wp_type, t_meal_time, total_return_amt, avg_return_tax, cnt_returns
  FROM cube_agg
  WHERE wp_type IS NOT NULL AND t_meal_time IS NOT NULL
  UNION
  SELECT wp_type, t_meal_time, total_return_amt, avg_return_tax, cnt_returns
  FROM cube_agg
  WHERE wp_type = 'ALL' OR t_meal_time = 'ALL'
),

key_set_a AS (
  SELECT DISTINCT wr_returning_customer_sk AS customer_sk
  FROM web_returns
  WHERE wr_return_amt > 150
),

key_set_b AS (
  SELECT DISTINCT wr_returning_customer_sk AS customer_sk
  FROM web_returns
  WHERE wr_return_quantity > 2
),

intersect_keys AS (
  SELECT customer_sk FROM key_set_a INTERSECT SELECT customer_sk FROM key_set_b
),

except_keys AS (
  SELECT customer_sk FROM key_set_a EXCEPT SELECT customer_sk FROM key_set_b
),

filtered_pages AS (
  SELECT wp_web_page_sk, wp_type, wp_url
  FROM web_page
  WHERE wp_web_page_sk IN (
    SELECT DISTINCT wr_web_page_sk
    FROM web_returns
    WHERE wr_return_amt > 200
  )
)
SELECT
  ua.wp_type,
  ua.t_meal_time,
  ua.total_return_amt,
  ua.avg_return_tax,
  ua.cnt_returns,
  fp.wp_url,
  ik.customer_sk AS intersect_customer_sk,
  ek.customer_sk AS except_customer_sk
FROM union_agg ua
JOIN filtered_pages fp ON ua.wp_type = fp.wp_type
LEFT JOIN intersect_keys ik ON 1 = 1
LEFT JOIN except_keys ek ON 1 = 1
ORDER BY ua.total_return_amt DESC NULLS LAST
LIMIT 100
