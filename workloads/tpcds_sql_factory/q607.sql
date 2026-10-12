WITH store_sales_inventory AS (
    SELECT
        s.s_store_id,
        s.s_city,
        d_sales.d_year,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        CASE 
            WHEN SUM(cs.cs_net_profit) > 200000 THEN 'Very High'
            WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High'
            WHEN SUM(cs.cs_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM catalog_sales cs
    JOIN inventory inv 
        ON cs.cs_item_sk = inv.inv_item_sk
       AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
       AND inv.inv_date_sk <= cs.cs_sold_date_sk
    JOIN date_dim d_sales 
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN store s 
        ON (s.s_closed_date_sk IS NULL OR cs.cs_sold_date_sk <= s.s_closed_date_sk)
    GROUP BY s.s_store_id, s.s_city, d_sales.d_year
)
SELECT
    s_store_id,
    s_city,
    d_year,
    total_profit,
    total_quantity,
    avg_inventory_on_hand,
    profit_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM store_sales_inventory
ORDER BY d_year, profit_rank_year
