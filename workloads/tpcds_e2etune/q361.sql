WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
),
sales_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        cd.cd_gender AS customer_gender,
        hd.hd_buy_potential AS buy_potential,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        AVG(i.avg_qty_on_hand) AS avg_inventory_on_hand
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inv_agg i
        ON cs.cs_item_sk = i.inv_item_sk
        AND cs.cs_ship_date_sk = i.inv_date_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cs.cs_ext_discount_amt BETWEEN 500 AND 3000
      AND cs.cs_ship_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY sm.sm_type, cd.cd_gender, hd.hd_buy_potential
    HAVING SUM(cs.cs_net_profit) > 5000
)
SELECT
    ship_mode_type,
    customer_gender,
    buy_potential,
    num_orders,
    total_net_profit,
    avg_discount,
    avg_inventory_on_hand,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
