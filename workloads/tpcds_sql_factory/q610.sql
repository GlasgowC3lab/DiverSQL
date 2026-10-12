WITH sales_inventory AS (
    SELECT
        s.s_store_id,
        s.s_city,
        d_sales.d_quarter_name,
        d_sales.d_quarter_seq,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        d_sales.d_date AS sale_date,
        d_inv.d_date AS inventory_date,
        DATE_DIFF('day', d_inv.d_date, d_sales.d_date) AS inventory_age_days
    FROM catalog_sales cs
    JOIN inventory inv
        ON cs.cs_item_sk = inv.inv_item_sk
       AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
       AND inv.inv_date_sk <= cs.cs_sold_date_sk
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN store s ON (s.s_closed_date_sk IS NULL OR cs.cs_sold_date_sk <= s.s_closed_date_sk)
),
quarter_agg AS (
    SELECT
        s_store_id,
        s_city,
        d_quarter_name,
        d_quarter_seq,
        SUM(cs_quantity) AS total_qty,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(inventory_age_days) AS avg_inventory_age,
        MIN(sale_date) AS first_sale_date,
        MAX(sale_date) AS last_sale_date
    FROM sales_inventory
    GROUP BY s_store_id, s_city, d_quarter_name, d_quarter_seq
)
SELECT
    s_store_id,
    s_city,
    d_quarter_name,
    total_qty,
    total_sales,
    total_profit,
    CASE 
        WHEN total_sales = 0 THEN NULL
        ELSE total_profit / total_sales
    END AS profit_margin,
    avg_inventory_age,
    CASE 
        WHEN (total_profit / NULLIF(total_sales,0)) >= 0.2 THEN 'Excellent'
        WHEN (total_profit / NULLIF(total_sales,0)) >= 0.1 THEN 'Good'
        WHEN (total_profit / NULLIF(total_sales,0)) >= 0.05 THEN 'Average'
        ELSE 'Poor'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY first_sale_date) AS first_sale_rank,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY last_sale_date DESC) AS last_sale_rank,
    DENSE_RANK() OVER (PARTITION BY d_quarter_name ORDER BY (total_profit / NULLIF(total_sales,0)) DESC) AS profit_rank_in_quarter
FROM quarter_agg
WHERE total_qty > 0
ORDER BY d_quarter_name, profit_rank_in_quarter
LIMIT 100
