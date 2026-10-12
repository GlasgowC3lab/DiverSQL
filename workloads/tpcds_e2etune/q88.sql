SELECT
    cc.cc_manager,
    p.p_promo_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(p.p_cost * i.inv_quantity_on_hand) AS promo_inventory_cost
FROM call_center cc
JOIN store s
    ON cc.cc_state = s.s_state
   AND cc.cc_city = s.s_city
JOIN promotion p
    ON cc.cc_open_date_sk = p.p_start_date_sk
JOIN inventory i
    ON i.inv_date_sk = p.p_start_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = p.p_end_date_sk
WHERE cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND i.inv_quantity_on_hand > 0
GROUP BY cc.cc_manager, p.p_promo_name
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 50
