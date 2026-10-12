WITH sales_filtered AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_ship_date_sk,
       cs.cs_bill_customer_sk,
       cs.cs_bill_addr_sk,
       cs.cs_ship_customer_sk,
       cs.cs_ship_addr_sk,
       cs.cs_call_center_sk,
       cs.cs_ship_mode_sk,
       cs.cs_promo_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_profit,
       cs.cs_quantity
   FROM catalog_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t_sold
     ON cs.cs_sold_time_sk = t_sold.t_time_sk
   WHERE d_sold.d_year = 2001
     AND t_sold.t_hour BETWEEN 9 AND 17
),

returns_set AS (
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   JOIN date_dim d_ret
     ON cr.cr_returned_date_sk = d_ret.d_date_sk
   WHERE d_ret.d_year = 2001
),

promo_set AS (
   SELECT cs.cs_order_number
   FROM catalog_sales cs
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d_promo_start
     ON p.p_start_date_sk = d_promo_start.d_date_sk
   WHERE d_promo_start.d_year = 2001
)

SELECT
    s.s_store_name,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    d_ship.d_month_seq AS ship_month,
    CASE
        WHEN SUM(sf.cs_net_profit) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_flag,
    SUM(sf.cs_ext_sales_price) AS total_sales,
    SUM(sf.cs_net_profit) AS total_profit,
    COUNT(DISTINCT sf.cs_order_number) AS num_orders,
    ca.ca_city,
    cust.c_first_name,
    cust.c_last_name,
    cust_agg.cust_total_sales
FROM sales_filtered sf
-- expose the sold‑date dimension for the store join
JOIN date_dim d_sold_outer
  ON sf.cs_sold_date_sk = d_sold_outer.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold_outer.d_date_sk
JOIN call_center cc
  ON sf.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN ship_mode sm
  ON sf.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON sf.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_ship
  ON sf.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer cust
  ON sf.cs_bill_customer_sk = cust.c_customer_sk
JOIN customer_address ca
  ON sf.cs_bill_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = sf.cs_order_number
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_sales_price) AS cust_total_sales
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = cust.c_customer_sk
) AS cust_agg
WHERE sf.cs_order_number IN (
    SELECT cr_order_number FROM returns_set
    INTERSECT
    SELECT cs_order_number FROM promo_set
)
GROUP BY
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    d_ship.d_month_seq,
    ca.ca_city,
    cust.c_first_name,
    cust.c_last_name,
    cust_agg.cust_total_sales
HAVING SUM(sf.cs_net_profit) > 10000
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100
