WITH sales_by_promo_state AS (
  SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    ca_sales.ca_state AS sale_state,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_coupon_amt) AS total_coupon_amt,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    SUM(ss.ss_quantity) AS total_quantity,
    MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
    MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
  FROM store_sales ss
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca_current
    ON c.c_current_addr_sk = ca_current.ca_address_sk
  WHERE p.p_discount_active = 'Y'
    AND p.p_start_date_sk >= 2451545
    AND p.p_end_date_sk <= 2459215
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2459215
    AND ca_current.ca_country = 'United States'
  GROUP BY p.p_promo_id, p.p_promo_name, ca_sales.ca_state
),

ranked_promotions AS (
  SELECT
    promo_id,
    promo_name,
    sale_state,
    total_net_profit,
    total_sales,
    total_quantity,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY sale_state ORDER BY profit_margin DESC) AS state_promo_rank
  FROM (
    SELECT
      promo_id,
      promo_name,
      sale_state,
      total_net_profit,
      total_sales,
      total_quantity,
      CASE WHEN total_sales > 0 THEN total_net_profit / total_sales ELSE 0 END AS profit_margin
    FROM sales_by_promo_state
    WHERE total_sales > 0
  )
)

SELECT
  promo_id,
  promo_name,
  sale_state,
  total_net_profit,
  total_sales,
  total_quantity,
  profit_margin,
  state_promo_rank
FROM ranked_promotions
WHERE state_promo_rank <= 3
ORDER BY sale_state, profit_margin DESC
