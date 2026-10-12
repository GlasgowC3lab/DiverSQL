WITH catalog_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        td.t_meal_time AS meal_time,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
        COUNT(*) AS catalog_return_cnt,
        ROW_NUMBER() OVER (PARTITION BY td.t_meal_time ORDER BY SUM(cr.cr_net_loss) DESC) AS catalog_rank_by_net_loss
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_catalog_page_number BETWEEN 1 AND 5
    GROUP BY w.w_warehouse_id, w.w_state, td.t_meal_time
),
web_agg AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_type,
        td.t_meal_time AS meal_time,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        AVG(wr.wr_return_amt) AS avg_web_return_amount,
        COUNT(*) AS web_return_cnt,
        ROW_NUMBER() OVER (PARTITION BY td.t_meal_time ORDER BY SUM(wr.wr_net_loss) DESC) AS web_rank_by_net_loss
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wp.wp_type IN ('product', 'category')
    GROUP BY wp.wp_web_page_id, wp.wp_type, td.t_meal_time
)
SELECT
    COALESCE(c.meal_time, w.meal_time) AS meal_time,
    c.w_warehouse_id,
    c.w_state,
    c.total_catalog_net_loss,
    c.avg_catalog_return_amount,
    c.catalog_return_cnt,
    c.catalog_rank_by_net_loss,
    w.wp_web_page_id,
    w.wp_type,
    w.total_web_net_loss,
    w.avg_web_return_amount,
    w.web_return_cnt,
    w.web_rank_by_net_loss,
    (COALESCE(c.total_catalog_net_loss, 0) - COALESCE(w.total_web_net_loss, 0)) AS net_loss_diff
FROM catalog_agg c
FULL OUTER JOIN web_agg w
    ON c.meal_time = w.meal_time
WHERE c.total_catalog_net_loss IS NOT NULL
   OR w.total_web_net_loss IS NOT NULL
ORDER BY meal_time, net_loss_diff DESC
