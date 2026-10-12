WITH inv_agg AS (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_city,
    cd_refunded.cd_education_status,
    cd_returning.cd_gender,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    MAX(inv_agg.total_inventory_on_hand) AS total_inventory_on_hand,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN inv_agg
    ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE cr.cr_return_amount > 1000
  AND cd_refunded.cd_education_status = 'College'
  AND cd_returning.cd_gender = 'M'
  AND w.w_country = 'United States'
GROUP BY w.w_city, cd_refunded.cd_education_status, cd_returning.cd_gender
HAVING SUM(cr.cr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 20
