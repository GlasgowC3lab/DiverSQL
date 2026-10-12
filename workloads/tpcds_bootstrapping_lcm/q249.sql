WITH cr_agg AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        SUM(cr_return_amount)                 AS total_catalog_return_amount,
        SUM(cr_return_tax)                    AS total_catalog_return_tax,
        SUM(cr_net_loss)                      AS total_catalog_net_loss,
        SUM(cr_return_quantity)               AS total_catalog_return_qty,
        COUNT(DISTINCT cr_order_number)       AS catalog_order_cnt
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
wr_agg AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt_inc_tax)            AS total_web_return_amount_inc_tax,
        SUM(wr_return_tax)                    AS total_web_return_tax,
        SUM(wr_net_loss)                      AS total_web_net_loss,
        SUM(wr_return_quantity)               AS total_web_return_qty,
        COUNT(DISTINCT wr_order_number)       AS web_order_cnt
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    CASE WHEN GROUPING(d.d_year) = 1 THEN 'ALL_YEARS' ELSE CAST(d.d_year AS varchar) END   AS year_group,
    CASE WHEN GROUPING(s.s_state) = 1 THEN 'ALL_STATES' ELSE s.s_state END               AS state_group,
    SUM(cr_agg.total_catalog_return_amount)                AS total_catalog_return_amount,
    SUM(wr_agg.total_web_return_amount_inc_tax)           AS total_web_return_amount_inc_tax,
    SUM(cr_agg.total_catalog_return_tax) + SUM(wr_agg.total_web_return_tax) AS total_return_tax,
    SUM(cr_agg.total_catalog_net_loss) + SUM(wr_agg.total_web_net_loss)       AS total_net_loss,
    SUM(cr_agg.catalog_order_cnt)                         AS catalog_order_cnt,
    SUM(wr_agg.web_order_cnt)                             AS web_order_cnt,
    (SUM(cr_agg.catalog_order_cnt) + SUM(wr_agg.web_order_cnt)) AS total_order_cnt,
    CASE
        WHEN (SUM(cr_agg.total_catalog_net_loss) + SUM(wr_agg.total_web_net_loss)) > 0 THEN 'LOSS'
        WHEN (SUM(cr_agg.total_catalog_net_loss) + SUM(wr_agg.total_web_net_loss)) < 0 THEN 'PROFIT'
        ELSE 'BREAK-EVEN'
    END                                                   AS overall_status
FROM date_dim d
LEFT JOIN cr_agg ON cr_agg.date_sk = d.d_date_sk
LEFT JOIN wr_agg ON wr_agg.date_sk = d.d_date_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2019 AND 2022
  AND s.s_state IS NOT NULL
GROUP BY ROLLUP(d.d_year, s.s_state)
HAVING SUM(cr_agg.total_catalog_return_amount) > 0
    OR SUM(wr_agg.total_web_return_amount_inc_tax) > 0
ORDER BY year_group, state_group
