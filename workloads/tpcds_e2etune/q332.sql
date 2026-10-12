WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    cc.cc_call_center_id,
    i.i_category,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_revenue,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(inv_agg.total_on_hand) AS total_inventory,
    CASE WHEN SUM(cs.cs_net_paid_inc_ship_tax) = 0 THEN 0
         ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid_inc_ship_tax)
    END AS profit_margin
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
WHERE cc.cc_state IN ('TN', 'GA')
  AND cc.cc_class = 'large'
  AND i.i_current_price > 100
  AND inv_agg.total_on_hand > 1000
GROUP BY cc.cc_call_center_id, i.i_category
HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 0
ORDER BY total_revenue DESC
LIMIT 100
