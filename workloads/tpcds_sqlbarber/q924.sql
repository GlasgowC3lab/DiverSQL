SELECT p.p_promo_name, SUM(cs.cs_net_paid) AS total_net_paid FROM catalog_sales cs JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk WHERE cs.cs_sold_date_sk = 2450835 GROUP BY p.p_promo_name
