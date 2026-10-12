WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_reason_sk,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451016 AND 2451091
      AND cr.cr_return_quantity > 10
      AND cr.cr_reason_sk IN (16, 17, 59)
),
joined AS (
    SELECT
        ws.web_state,
        ws.web_city,
        fr.cr_reason_sk,
        fr.cr_net_loss,
        fr.cr_return_quantity,
        fr.cr_return_amount
    FROM filtered_returns fr
    INNER JOIN web_site ws
        ON fr.cr_returned_date_sk = ws.web_open_date_sk
    WHERE ws.web_state = 'CA'
),
aggregated AS (
    SELECT
        web_state,
        web_city,
        cr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_quantity) AS avg_return_qty,
        SUM(cr_return_amount) AS total_return_amount
    FROM joined
    GROUP BY web_state, web_city, cr_reason_sk
    HAVING SUM(cr_net_loss) > 1000
)
SELECT
    web_state,
    web_city,
    cr_reason_sk,
    return_cnt,
    total_net_loss,
    avg_return_qty,
    total_return_amount,
    RANK() OVER (PARTITION BY web_state ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 50
