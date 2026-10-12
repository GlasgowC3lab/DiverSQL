WITH monthly_customer_sales AS (
  SELECT
    d.d_year,
    d.d_moy,
    c.c_customer_id,
    s.s_store_name,
    i.i_item_id,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns_loss,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS promo_discount,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_moy ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
    AND s.s_state = 'TN'
  GROUP BY d.d_year, d.d_moy, c.c_customer_id, s.s_store_name, i.i_item_id
)
SELECT
  d_year,
  d_moy,
  c_customer_id,
  s_store_name,
  i_item_id,
  total_sales,
  total_profit,
  distinct_items,
  total_returns_loss,
  promo_discount
FROM monthly_customer_sales
WHERE profit_rank <= 10
ORDER BY d_year, d_moy, profit_rank
