WITH ship_mode_agg AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_returned_date_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
        MAX(wp.wp_link_count) AS max_link_count
    FROM catalog_returns cr
    JOIN web_page wp
        ON cr.cr_returned_date_sk = wp.wp_access_date_sk
    WHERE cr.cr_ship_mode_sk IN (2, 12, 13)
      AND cr.cr_net_loss > 50
      AND wp.wp_link_count >= 200
    GROUP BY cr.cr_ship_mode_sk, cr.cr_returned_date_sk
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    cr_ship_mode_sk,
    cr_returned_date_sk,
    total_net_loss,
    avg_return_qty,
    distinct_customers,
    max_link_count,
    RANK() OVER (PARTITION BY cr_ship_mode_sk ORDER BY total_net_loss DESC) AS net_loss_rank
FROM ship_mode_agg
ORDER BY total_net_loss DESC
LIMIT 50
