WITH ship_mode_expanded AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_code,
        sm.sm_carrier,
        sm.sm_contract,
        mode_attr
    FROM ship_mode sm
    CROSS JOIN UNNEST(ARRAY[sm.sm_type, sm.sm_code]) AS t(mode_attr)
)
SELECT
    cp.cp_catalog_page_id,
    i.i_item_id,
    d_sold.d_date        AS sold_date,
    d_ship.d_date        AS ship_date,
    inv.inv_quantity_on_hand,
    sm_exp.mode_attr    AS ship_mode_attribute,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_net_profit,
    RANK() OVER (PARTITION BY i.i_category_id ORDER BY cs.cs_net_profit DESC)      AS profit_rank_by_category,
    ROW_NUMBER() OVER (ORDER BY cs.cs_net_profit DESC)                         AS overall_profit_rank
FROM catalog_page cp
FULL OUTER JOIN catalog_sales cs
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
INNER JOIN ship_mode_expanded sm_exp
    ON cs.cs_ship_mode_sk = sm_exp.sm_ship_mode_sk
WHERE
    i.i_category_id IN (2, 3, 4, 6, 9)
    AND i.i_size <> 'N/A'
    AND d_sold.d_holiday = 'N'
    AND sm_exp.sm_code = 'AIR'
    AND cs.cs_quantity > 1
    AND cs.cs_net_profit > 0
    AND d_sold.d_year = 2001
ORDER BY cs.cs_net_profit DESC
LIMIT 100
