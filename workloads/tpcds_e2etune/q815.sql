SELECT
    w.w_city AS warehouse_city,
    i.i_category AS product_category,
    i.i_brand AS product_brand,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE WHEN SUM(inv.inv_quantity_on_hand) = 0 THEN NULL
         ELSE SUM(cs.cs_net_profit) / SUM(inv.inv_quantity_on_hand) END AS profit_per_inventory,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_ext_tax > 50
  AND cs.cs_ship_mode_sk IN (1, 3, 5)
  AND ca.ca_state = 'CA'
  AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
GROUP BY w.w_city, i.i_category, i.i_brand
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
