SELECT
    w.w_state,
    hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(cs.cs_order_number) AS order_count
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_sold_date_sk = 2450855
  AND w.w_state = 'SD'
GROUP BY w.w_state, hd.hd_buy_potential
ORDER BY total_net_paid DESC
LIMIT 100
