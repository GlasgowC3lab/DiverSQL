WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity,
        MAX(inv_quantity_on_hand) AS max_quantity
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    cc.cc_name,
    wp.wp_type,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    (SELECT AVG(i2.i_wholesale_cost) FROM item i2) AS overall_avg_wholesale_cost,
    (AVG(i.i_wholesale_cost) - (SELECT AVG(i3.i_wholesale_cost) FROM item i3)) AS wholesale_cost_diff
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk
JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_class_id IN (2, 6, 8)
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cd.cd_credit_rating = 'A'
GROUP BY d.d_year, i.i_category, i.i_brand, w.w_warehouse_name, cc.cc_name, wp.wp_type
HAVING SUM(sr.sr_net_loss) > 0
   AND AVG(i.i_wholesale_cost) > (SELECT AVG(i4.i_wholesale_cost) FROM item i4)
ORDER BY total_net_loss DESC
LIMIT 100
