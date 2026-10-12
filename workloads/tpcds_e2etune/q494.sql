SELECT
    cp.cp_catalog_page_number,
    cp.cp_catalog_number,
    t.t_shift,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_list_price), 0) AS profit_margin
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cp.cp_end_date_sk BETWEEN 2450900 AND 2451100
  AND hd.hd_buy_potential = '500+'
  AND c.c_preferred_cust_flag = 'Y'
  AND t.t_shift IN ('Morning', 'Afternoon')
GROUP BY cp.cp_catalog_page_number,
         cp.cp_catalog_number,
         t.t_shift,
         hd.hd_buy_potential
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 20
