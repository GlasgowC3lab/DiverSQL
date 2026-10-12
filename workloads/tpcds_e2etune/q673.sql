WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_warehouse_sk
),
sales_agg AS (
    SELECT
        sm.sm_type AS ship_mode,
        p.p_promo_name AS promotion_name,
        hd_bill.hd_buy_potential AS buyer_buy_potential,
        inv_agg.total_inventory,
        COUNT(*) AS num_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    WHERE cs.cs_sales_price > 50
      AND cs.cs_quantity >= 20
      AND p.p_cost > 1000
      AND w.w_gmt_offset BETWEEN -5 AND 5
    GROUP BY
        sm.sm_type,
        p.p_promo_name,
        hd_bill.hd_buy_potential,
        inv_agg.total_inventory
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    ship_mode,
    promotion_name,
    buyer_buy_potential,
    total_inventory,
    num_sales,
    total_net_profit,
    avg_sales_price,
    total_quantity,
    RANK() OVER (PARTITION BY promotion_name ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
