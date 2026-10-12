WITH
    cr_pre AS (
        SELECT
            cr_item_sk,
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_warehouse_sk,
            SUM(cr_net_loss) AS total_cr_loss,
            COUNT(*) AS cr_cnt
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY cr_item_sk, cr_returned_date_sk, cr_returned_time_sk, cr_warehouse_sk
    ),
    wr_pre AS (
        SELECT
            wr_item_sk,
            wr_returned_date_sk,
            wr_returned_time_sk,
            CAST(NULL AS INTEGER) AS wr_warehouse_sk,
            SUM(wr_net_loss) AS total_wr_loss,
            COUNT(*) AS wr_cnt
        FROM web_returns
        WHERE wr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY wr_item_sk, wr_returned_date_sk, wr_returned_time_sk
    ),
    joined_returns AS (
        SELECT
            COALESCE(cr_pre.cr_item_sk, wr_pre.wr_item_sk) AS item_sk,
            COALESCE(cr_pre.cr_returned_date_sk, wr_pre.wr_returned_date_sk) AS date_sk,
            COALESCE(cr_pre.cr_returned_time_sk, wr_pre.wr_returned_time_sk) AS time_sk,
            COALESCE(cr_pre.cr_warehouse_sk, wr_pre.wr_warehouse_sk) AS warehouse_sk,
            cr_pre.total_cr_loss,
            cr_pre.cr_cnt,
            wr_pre.total_wr_loss,
            wr_pre.wr_cnt
        FROM cr_pre
        FULL OUTER JOIN wr_pre
            ON cr_pre.cr_item_sk = wr_pre.wr_item_sk
            AND cr_pre.cr_returned_date_sk = wr_pre.wr_returned_date_sk
            AND cr_pre.cr_returned_time_sk = wr_pre.wr_returned_time_sk
    )
SELECT
    i.i_manufact,
    i.i_category,
    d.d_year,
    t.t_hour,
    w.w_warehouse_name,
    SUM(COALESCE(jr.total_cr_loss, 0) + COALESCE(jr.total_wr_loss, 0)) AS total_loss,
    COUNT(*) AS rows_cnt,
    MIN(COALESCE(jr.total_cr_loss, 0) + COALESCE(jr.total_wr_loss, 0)) AS min_loss,
    MAX(COALESCE(jr.total_cr_loss, 0) + COALESCE(jr.total_wr_loss, 0)) AS max_loss
FROM joined_returns jr
JOIN item i ON jr.item_sk = i.i_item_sk
JOIN date_dim d ON jr.date_sk = d.d_date_sk
JOIN time_dim t ON jr.time_sk = t.t_time_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    AND p.p_start_date_sk <= d.d_date_sk
    AND p.p_end_date_sk >= d.d_date_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = jr.warehouse_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND i.i_manufact_id IN (338, 260)
  AND i.i_formulation = '42214rosy28066558020'
  AND p.p_purpose = 'Unknown'
  AND p.p_channel_radio = 'N'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY i.i_manufact, i.i_category, d.d_year, t.t_hour, w.w_warehouse_name
HAVING SUM(COALESCE(jr.total_cr_loss, 0) + COALESCE(jr.total_wr_loss, 0)) > 1000
ORDER BY total_loss DESC
LIMIT 100
