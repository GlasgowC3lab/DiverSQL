SELECT
    cr.cr_item_sk,
    cr_avg.avg_item_loss,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) / cr_avg.avg_item_loss AS loss_ratio
FROM catalog_returns cr
JOIN (
    SELECT
        cr_item_sk,
        AVG(cr_net_loss) AS avg_item_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
) cr_avg
    ON cr.cr_item_sk = cr_avg.cr_item_sk
WHERE cr.cr_returned_date_sk >= 20220101
  AND cr.cr_net_loss > cr_avg.avg_item_loss * 2
GROUP BY cr.cr_item_sk, cr_avg.avg_item_loss
HAVING COUNT(*) >= 5
ORDER BY loss_ratio DESC
LIMIT 10
