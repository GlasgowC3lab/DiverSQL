SELECT
    fr.cr_reason_sk,
    agg.total_return_qty,
    agg.total_net_loss,
    ROUND(AVG(fr.cr_reversed_charge), 2) AS avg_reversed_charge,
    MAX(fr.cr_refunded_cash) AS max_refunded_cash
FROM catalog_returns fr
JOIN (
    SELECT
        cr_reason_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    WHERE cr_call_center_sk IN (1, 13, 20)
      AND cr_return_quantity > 20
    GROUP BY cr_reason_sk
    HAVING SUM(cr_net_loss) > 0
) agg
  ON fr.cr_reason_sk = agg.cr_reason_sk
WHERE fr.cr_reason_sk IN (9, 16, 59)
GROUP BY fr.cr_reason_sk, agg.total_return_qty, agg.total_net_loss
ORDER BY agg.total_net_loss DESC
LIMIT 10
