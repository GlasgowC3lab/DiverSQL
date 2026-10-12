WITH per_item AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_manufact_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_ship,
        AVG(ws.ws_quantity) AS avg_ws_quantity
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_manufact_id IN (86, 214)
      AND cr.cr_return_amount > 20
      AND ws.ws_net_paid_inc_ship > 500
    GROUP BY i.i_item_sk, i.i_item_id, i.i_manufact_id
)
SELECT
    pi.i_item_id,
    pi.i_manufact_id,
    pi.total_return_amount,
    pi.total_return_tax,
    pi.return_cnt,
    pi.total_net_paid_ship,
    pi.avg_ws_quantity,
    ROW_NUMBER() OVER (ORDER BY pi.total_return_amount DESC) AS rn,
    (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_manufact_id = pi.i_manufact_id
    ) AS avg_price_by_manufact
FROM per_item pi
WHERE pi.return_cnt > 5
  AND pi.total_return_tax > 50
  AND pi.total_net_paid_ship > 2000
ORDER BY pi.total_return_amount DESC
LIMIT 100
