WITH max_price AS (
    SELECT MAX(i_current_price) AS max_price
    FROM item
    WHERE i_category = 'Electronics'
)
SELECT
    category,
    attribute,
    metric1,
    metric2,
    label
FROM (
    SELECT
        i.i_category AS category,
        cc.cc_state AS attribute,
        SUM(cr.cr_return_amount) AS metric1,
        SUM(cr.cr_refunded_cash) AS metric2,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS label
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amount > (SELECT max_price FROM max_price)
    GROUP BY GROUPING SETS (
        (i.i_category, cc.cc_state),
        (i.i_category),
        ()
    )
    UNION
    SELECT
        i.i_category AS category,
        i.i_color AS attribute,
        SUM(inv.inv_quantity_on_hand) AS metric1,
        CAST(NULL AS decimal(7,2)) AS metric2,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'Plenty' ELSE 'LowStock' END AS label
    FROM inventory inv
    FULL OUTER JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (i.i_category, i.i_color),
        (i.i_category),
        ()
    )
) AS unioned
ORDER BY category, metric1 DESC
LIMIT 100
