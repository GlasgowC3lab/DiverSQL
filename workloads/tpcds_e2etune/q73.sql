SELECT
    p.p_promo_name,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM web_returns wr
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN inventory i ON wr.wr_item_sk = i.inv_item_sk AND wr.wr_returned_date_sk = i.inv_date_sk
JOIN promotion p ON wr.wr_item_sk = p.p_item_sk AND wr.wr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451053
  AND p.p_discount_active = 'Y'
GROUP BY p.p_promo_name, r.r_reason_desc
HAVING SUM(wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
