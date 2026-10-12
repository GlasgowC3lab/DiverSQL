WITH catalog_agg AS (
    SELECT
        cr_returned_date_sk   AS date_sk,
        cr_returned_time_sk   AS time_sk,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(cr_net_loss)      AS total_catalog_net_loss,
        COUNT(*)              AS catalog_return_count,
        AVG(cr_return_quantity) AS avg_catalog_return_qty
    FROM catalog_returns
    GROUP BY cr_returned_date_sk, cr_returned_time_sk
),
web_agg AS (
    SELECT
        wr_returned_date_sk   AS date_sk,
        wr_returned_time_sk   AS time_sk,
        SUM(wr_return_amt)    AS total_web_return_amount,
        SUM(wr_net_loss)      AS total_web_net_loss,
        COUNT(*)              AS web_return_count,
        AVG(wr_return_quantity) AS avg_web_return_qty
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_returned_time_sk
),
combined AS (
    SELECT
        COALESCE(ca.date_sk, wa.date_sk)                     AS date_sk,
        COALESCE(ca.time_sk, wa.time_sk)                     AS time_sk,
        ca.total_catalog_return_amount,
        ca.total_catalog_net_loss,
        ca.catalog_return_count,
        ca.avg_catalog_return_qty,
        wa.total_web_return_amount,
        wa.total_web_net_loss,
        wa.web_return_count,
        wa.avg_web_return_qty
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa
        ON ca.date_sk = wa.date_sk
       AND ca.time_sk = wa.time_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    COALESCE(combined.total_catalog_return_amount, 0) AS total_catalog_return_amount,
    COALESCE(combined.total_web_return_amount, 0)     AS total_web_return_amount,
    COALESCE(combined.total_catalog_net_loss, 0) + COALESCE(combined.total_web_net_loss, 0) AS total_net_loss,
    COALESCE(combined.catalog_return_count, 0)       AS catalog_return_count,
    COALESCE(combined.web_return_count, 0)           AS web_return_count,
    COALESCE(combined.avg_catalog_return_qty, 0)    AS avg_catalog_return_qty,
    COALESCE(combined.avg_web_return_qty, 0)        AS avg_web_return_qty,
    (COALESCE(combined.total_catalog_return_amount, 0) + COALESCE(combined.total_web_return_amount, 0)) AS total_return_amount
FROM combined
JOIN date_dim d ON combined.date_sk = d.d_date_sk
JOIN time_dim t ON combined.time_sk = t.t_time_sk
JOIN store s     ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2020
ORDER BY total_net_loss DESC
LIMIT 100
