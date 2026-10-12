SELECT
    cp.cp_department,
    d_sold.d_year,
    d_sold.d_moy AS month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) AS profit_margin,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    RANK() OVER (PARTITION BY d_sold.d_year, d_sold.d_moy ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE d_sold.d_year = 2001
  AND cp.cp_type = 'monthly'
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'CA'
GROUP BY cp.cp_department, d_sold.d_year, d_sold.d_moy
ORDER BY total_net_profit DESC
LIMIT 100
