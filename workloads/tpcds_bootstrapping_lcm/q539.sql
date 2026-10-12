WITH inventory_bucket AS (
    SELECT
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        CASE
            WHEN i.inv_quantity_on_hand < 100 THEN 'Low'
            WHEN i.inv_quantity_on_hand BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS quantity_bucket,
        i.inv_date_sk
    FROM inventory i
)
SELECT
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    s.s_state AS store_state,
    wp.wp_type AS page_type,
    ib.quantity_bucket,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    AVG(date_diff('day', d_ret.d_date, d_access.d_date)) AS avg_days_between_creation_and_access
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN inventory_bucket ib
    ON ib.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cr.cr_return_amount > 0
GROUP BY
    d_ret.d_year,
    d_ret.d_moy,
    s.s_state,
    wp.wp_type,
    ib.quantity_bucket
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
