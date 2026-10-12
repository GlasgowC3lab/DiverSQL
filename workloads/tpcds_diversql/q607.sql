WITH ss AS (
    SELECT
        ss.ss_sold_time_sk AS time_sk,
        ss.ss_ext_sales_price,
        td.t_time_id,
        td.t_meal_time
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE regexp_like(td.t_time_id, '^A{8}B')
      AND td.t_meal_time LIKE '%lunch%'
      AND ss.ss_ext_sales_price > 500
),
cr AS (
    SELECT
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_return_amount,
        td.t_time_id,
        td.t_meal_time
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 0
      AND td.t_meal_time LIKE '%dinner%'
)
SELECT
    COALESCE(ss.time_sk, cr.time_sk) AS time_sk,
    COALESCE(ss.t_time_id, cr.t_time_id) AS time_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS avg_return_amount_overall
FROM ss
FULL OUTER JOIN cr
    ON ss.time_sk = cr.time_sk
WHERE COALESCE(ss.time_sk, cr.time_sk) NOT IN (
    SELECT wr.wr_returned_time_sk
    FROM web_returns wr
    WHERE wr.wr_net_loss > 0
)
GROUP BY 1, 2
ORDER BY total_sales DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
