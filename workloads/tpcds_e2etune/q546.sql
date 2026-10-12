WITH cat_ret AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(cr.cr_return_quantity) AS cat_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS cat_orders
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_type = 'monthly'
      AND td.t_shift = 'Evening'
    GROUP BY cp.cp_department, td.t_hour, r.r_reason_desc
),
web_ret AS (
    SELECT
        'WEB' AS department,
        td.t_hour,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS web_orders
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_shift = 'Evening'
    GROUP BY td.t_hour, r.r_reason_desc
)
SELECT
    COALESCE(c.cp_department, w.department) AS channel_department,
    COALESCE(c.t_hour, w.t_hour) AS hour_of_day,
    COALESCE(c.r_reason_desc, w.r_reason_desc) AS reason,
    COALESCE(c.cat_net_loss, 0) AS catalog_net_loss,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    (COALESCE(c.cat_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_net_loss,
    (COALESCE(c.cat_return_qty, 0) + COALESCE(w.web_return_qty, 0)) AS total_return_qty,
    CASE 
        WHEN (COALESCE(c.cat_net_loss, 0) + COALESCE(w.web_net_loss, 0)) = 0 THEN 0
        ELSE COALESCE(c.cat_net_loss, 0) / (COALESCE(c.cat_net_loss, 0) + COALESCE(w.web_net_loss, 0))
    END AS catalog_loss_share
FROM cat_ret c
FULL OUTER JOIN web_ret w
  ON c.t_hour = w.t_hour
 AND c.r_reason_desc = w.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 20
