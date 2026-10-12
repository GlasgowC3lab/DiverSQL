WITH sales_by_mode AS (
    -- Sales for AIR ship mode in the year 2001
    SELECT
        d_sold.d_year AS year,
        d_sold.d_moy  AS month,
        sm.sm_type    AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND d_sold.d_year = 2001
    GROUP BY d_sold.d_year, d_sold.d_moy, sm.sm_type

    UNION ALL

    -- Sales for GROUND ship mode in the year 2001
    SELECT
        d_sold.d_year AS year,
        d_sold.d_moy  AS month,
        sm.sm_type    AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'GROUND'
      AND d_sold.d_year = 2001
    GROUP BY d_sold.d_year, d_sold.d_moy, sm.sm_type
)
SELECT
    sbm.year,
    sbm.month,
    sbm.ship_mode_type,
    sbm.total_net_profit,
    (
        SELECT AVG(inv.inv_quantity_on_hand)
        FROM inventory inv
        JOIN date_dim d_inv
            ON inv.inv_date_sk = d_inv.d_date_sk
        WHERE d_inv.d_year = sbm.year
          AND d_inv.d_moy  = sbm.month
    ) AS avg_inventory_qty_on_hand
FROM sales_by_mode sbm
ORDER BY sbm.year, sbm.month, sbm.ship_mode_type
