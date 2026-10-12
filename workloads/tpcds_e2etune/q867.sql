WITH return_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        sm.sm_type,
        cp.cp_type,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN web_page wp ON c_ret.c_customer_sk = wp.wp_customer_sk
    WHERE cp.cp_type = 'monthly'
      AND cr.cr_returned_date_sk BETWEEN 2450996 AND 2451178
      AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 10)
    GROUP BY i.i_category, i.i_brand, sm.sm_type, cp.cp_type
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    ra.i_category,
    ra.i_brand,
    ra.sm_type,
    ra.cp_type,
    ra.distinct_returning_customers,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.avg_return_quantity,
    RANK() OVER (ORDER BY ra.total_return_amount DESC) AS return_amount_rank
FROM return_agg ra
ORDER BY ra.total_return_amount DESC
LIMIT 100
