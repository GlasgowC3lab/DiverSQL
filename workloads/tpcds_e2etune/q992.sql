SELECT
    cc.cc_name,
    cc.cc_city,
    i.i_category,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM
    catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND inv.inv_date_sk = cr.cr_returned_date_sk
    LEFT JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    LEFT JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
WHERE
    cr.cr_returned_date_sk >= 2450000
    AND cc.cc_class = 'large'
    AND i.i_category IS NOT NULL
    AND cust_ret.c_preferred_cust_flag = 'Y'
    AND hd.hd_vehicle_count >= 2
GROUP BY
    cc.cc_name,
    cc.cc_city,
    i.i_category
HAVING
    SUM(cr.cr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
