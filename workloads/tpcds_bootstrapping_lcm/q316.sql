WITH inv_data AS (
    SELECT 
        i.inv_warehouse_sk,
        DATE_TRUNC('quarter', d.d_date) AS quarter_start,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY i.inv_warehouse_sk, DATE_TRUNC('quarter', d.d_date)
),
ret_data AS (
    SELECT 
        DATE_TRUNC('quarter', d.d_date) AS quarter_start,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY DATE_TRUNC('quarter', d.d_date)
)
SELECT 
    d.d_year,
    d.d_quarter_name,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    s.s_store_name,
    s.s_city AS store_city,
    COALESCE(i.total_quantity_on_hand, 0) AS total_inventory_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_tax, 0) AS total_return_tax,
    CASE 
        WHEN COALESCE(i.total_quantity_on_hand, 0) = 0 THEN NULL
        ELSE round((COALESCE(r.total_return_quantity, 0) / COALESCE(i.total_quantity_on_hand, 0)) * 100, 2)
    END AS return_qty_percent_of_inventory,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_quarter_name ORDER BY COALESCE(r.total_return_amount, 0) DESC) AS quarterly_return_rank
FROM date_dim d
LEFT JOIN inv_data i ON i.quarter_start = DATE_TRUNC('quarter', d.d_date)
LEFT JOIN ret_data r ON r.quarter_start = DATE_TRUNC('quarter', d.d_date)
LEFT JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND w.w_country = 'United States'
GROUP BY 
    d.d_year,
    d.d_quarter_name,
    w.w_warehouse_name,
    w.w_city,
    s.s_store_name,
    s.s_city,
    i.total_quantity_on_hand,
    r.total_return_quantity,
    r.total_return_amount,
    r.total_return_tax
ORDER BY d.d_year, d.d_quarter_name, total_return_amount DESC
LIMIT 100
