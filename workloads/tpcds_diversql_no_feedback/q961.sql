WITH
    sales_agg AS (
        SELECT
            td.t_sub_shift,
            td.t_hour,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE ss.ss_quantity > 20
          AND td.t_hour BETWEEN 6 AND 18
        GROUP BY td.t_sub_shift, td.t_hour
    ),
    returns_agg AS (
        SELECT
            td.t_sub_shift,
            td.t_hour,
            SUM(sr.sr_return_amt_inc_tax) AS total_returns,
            COUNT(*) AS returns_cnt
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        WHERE sr.sr_return_quantity > 0
          AND td.t_hour BETWEEN 6 AND 18
        GROUP BY td.t_sub_shift, td.t_hour
    ),
    combined AS (
        SELECT t_sub_shift, t_hour, total_sales AS amount, sales_cnt AS cnt, 'sale'   AS type
        FROM sales_agg
        UNION ALL
        SELECT t_sub_shift, t_hour, total_returns AS amount, returns_cnt AS cnt, 'return' AS type
        FROM returns_agg
    ),
    small_dim AS (
        SELECT DISTINCT t_sub_shift
        FROM time_dim
        WHERE t_sub_shift IN ('morning', 'afternoon', 'evening')
    )
SELECT
    sd.t_sub_shift      AS dim_sub_shift,
    c.t_sub_shift,
    c.t_hour,
    c.type,
    c.amount,
    c.cnt,
    LAG(c.amount) OVER (PARTITION BY c.t_sub_shift ORDER BY c.t_hour)               AS prev_amount,
    SUM(c.amount) OVER (PARTITION BY c.t_sub_shift ORDER BY c.t_hour
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM combined c
CROSS JOIN small_dim sd
ORDER BY dim_sub_shift, c.t_hour, c.type
LIMIT 100
