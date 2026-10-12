WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        cp.cp_department AS department,
        cp.cp_type AS type,
        cp.cp_catalog_page_number AS page_number,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_count,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_value_returns
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY cp.cp_catalog_page_id, cp.cp_department, cp.cp_type, cp.cp_catalog_page_number
)
SELECT
    cp_id,
    department,
    type,
    page_number,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    return_count,
    distinct_items_returned,
    high_value_returns,
    RANK() OVER (PARTITION BY department ORDER BY total_net_loss DESC) AS dept_net_loss_rank,
    DENSE_RANK() OVER (PARTITION BY type ORDER BY total_return_amount DESC) AS type_return_amount_dense_rank,
    CASE
        WHEN total_net_loss > 5000 THEN 'HIGH'
        WHEN total_net_loss > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_loss_category
FROM page_returns
ORDER BY department, dept_net_loss_rank
