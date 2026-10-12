WITH filtered_returns AS (
    SELECT cr.cr_item_sk,
           cr.cr_return_amount,
           cr.cr_return_quantity,
           cr.cr_fee,
           cr.cr_net_loss,
           cr.cr_call_center_sk,
           cr.cr_refunded_cdemo_sk,
           cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
      AND cr.cr_fee <= 42.59
      AND cr.cr_call_center_sk IN (19, 40, 38)
      AND cr.cr_refunded_cdemo_sk IN (29085, 519430)
),
agg AS (
    SELECT i.i_category,
           i.i_brand,
           i.i_color,
           COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
           SUM(fr.cr_return_amount) AS total_return_amount,
           AVG(fr.cr_return_quantity) AS avg_return_qty,
           SUM(fr.cr_fee) AS total_fee,
           SUM(fr.cr_net_loss) AS total_net_loss
    FROM filtered_returns fr
    JOIN item i ON fr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, i.i_color
    HAVING SUM(fr.cr_return_amount) > 5000
)
SELECT i_category,
       i_brand,
       i_color,
       distinct_orders,
       total_return_amount,
       avg_return_qty,
       total_fee,
       total_net_loss,
       RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY return_amount_rank
LIMIT 50
