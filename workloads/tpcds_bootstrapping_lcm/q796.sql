SELECT
    s.s_store_id,
    d.d_year,
    CASE
        WHEN d.d_moy IN (12, 1, 2) THEN 'Winter'
        WHEN d.d_moy IN (3, 4, 5) THEN 'Spring'
        WHEN d.d_moy IN (6, 7, 8) THEN 'Summer'
        WHEN d.d_moy IN (9, 10, 11) THEN 'Fall'
        ELSE 'Unknown'
    END AS season,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_quantity) AS avg_quantity,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0
        ELSE (SUM(cs.cs_net_profit) - SUM(wr.wr_return_amt)) / SUM(cs.cs_ext_sales_price)
    END AS profit_margin_adj
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    d.d_year,
    CASE
        WHEN d.d_moy IN (12, 1, 2) THEN 'Winter'
        WHEN d.d_moy IN (3, 4, 5) THEN 'Spring'
        WHEN d.d_moy IN (6, 7, 8) THEN 'Summer'
        WHEN d.d_moy IN (9, 10, 11) THEN 'Fall'
        ELSE 'Unknown'
    END
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
