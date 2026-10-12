SELECT
    cc.cc_state,
    cc.cc_call_center_id,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) DESC) AS profit_rank
FROM
    catalog_sales cs
JOIN
    date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN
    call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN
    item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN
    catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
JOIN
    inventory inv ON inv.inv_item_sk = i.i_item_sk
                AND inv.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND cc.cc_tax_percentage > 0.05
    AND cc.cc_state IN ('TN', 'GA', 'MI')
GROUP BY
    cc.cc_state,
    cc.cc_call_center_id,
    i.i_category
HAVING
    (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) > 0
ORDER BY
    net_profit_after_returns DESC
LIMIT 10
