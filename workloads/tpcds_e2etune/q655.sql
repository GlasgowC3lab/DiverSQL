SELECT
    d_sold.d_year,
    d_sold.d_moy AS month,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_days,
    RANK() OVER (PARTITION BY d_sold.d_year, d_sold.d_moy ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_net_profit ELSE 0 END) AS promo_net_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_net_profit ELSE 0 END) / SUM(cs.cs_net_profit) AS promo_profit_ratio
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
  AND cs.cs_warehouse_sk IN (11, 3, 16)
  AND cs.cs_net_paid_inc_ship > 2000
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY d_sold.d_year, d_sold.d_moy, i.i_category
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY d_sold.d_year, d_sold.d_moy, profit_rank
LIMIT 200
