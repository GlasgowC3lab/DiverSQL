WITH cat_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        sm.sm_type AS ship_mode_type,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON cr.cr_item_sk = inv.inv_item_sk AND cr.cr_returned_date_sk = inv.inv_date_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY r.r_reason_desc, cd.cd_gender, cd.cd_education_status, sm.sm_type
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        NULL AS ship_mode_type,
        SUM(wr.wr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON wr.wr_item_sk = inv.inv_item_sk AND wr.wr_returned_date_sk = inv.inv_date_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY r.r_reason_desc, cd.cd_gender, cd.cd_education_status
)
SELECT
    COALESCE(cat.reason_desc, web.reason_desc) AS reason_desc,
    COALESCE(cat.gender, web.gender) AS gender,
    COALESCE(cat.education_status, web.education_status) AS education_status,
    COALESCE(cat.ship_mode_type, web.ship_mode_type) AS ship_mode_type,
    SUM(COALESCE(cat.net_loss, 0) + COALESCE(web.net_loss, 0)) AS total_net_loss,
    SUM(COALESCE(cat.return_cnt, 0) + COALESCE(web.return_cnt, 0)) AS total_returns,
    AVG(cat.avg_ship_cost) AS avg_ship_cost,
    AVG(web.avg_return_qty) AS avg_return_qty,
    AVG(COALESCE(cat.avg_inventory_on_hand, web.avg_inventory_on_hand)) AS avg_inventory_on_hand,
    SUM(COALESCE(cat.total_return_qty, 0) + COALESCE(web.total_return_qty, 0)) AS total_return_quantity
FROM cat_ret cat
FULL OUTER JOIN web_ret web
    ON cat.reason_desc = web.reason_desc
    AND cat.gender = web.gender
    AND cat.education_status = web.education_status
    AND cat.ship_mode_type = web.ship_mode_type
GROUP BY
    COALESCE(cat.reason_desc, web.reason_desc),
    COALESCE(cat.gender, web.gender),
    COALESCE(cat.education_status, web.education_status),
    COALESCE(cat.ship_mode_type, web.ship_mode_type)
ORDER BY total_net_loss DESC
LIMIT 100
