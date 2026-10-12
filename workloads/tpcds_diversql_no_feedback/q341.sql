WITH cs_agg AS (
   SELECT
       cs_bill_customer_sk AS customer_sk,
       cs_sold_date_sk AS sold_date_sk,
       cs_promo_sk AS promo_sk,
       SUM(cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_cnt
   FROM catalog_sales
   WHERE cs_wholesale_cost > 30
   GROUP BY cs_bill_customer_sk, cs_sold_date_sk, cs_promo_sk
)
SELECT
    c.c_customer_id,
    d.d_year,
    p.p_promo_name,
    ca.ca_state,
    hd.hd_income_band_sk,
    cs_agg.total_sales,
    cs_agg.order_cnt,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category
FROM cs_agg
JOIN customer c
  ON cs_agg.customer_sk = c.c_customer_sk
JOIN date_dim d
  ON cs_agg.sold_date_sk = d.d_date_sk
JOIN promotion p
  ON cs_agg.promo_sk = p.p_promo_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss
  ON ss.ss_customer_sk = c.c_customer_sk
  AND ss.ss_hdemo_sk = hd.hd_demo_sk
  AND ss.ss_addr_sk = ca.ca_address_sk
  AND ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
WHERE
    d.d_year = 2001
    AND p.p_channel_event = 'N'
    AND ca.ca_state = 'CA'
    AND c.c_preferred_cust_flag = 'Y'
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_promo_sk = p.p_promo_sk
          AND cs2.cs_wholesale_cost > 50
    )
GROUP BY
    c.c_customer_id,
    d.d_year,
    p.p_promo_name,
    ca.ca_state,
    hd.hd_income_band_sk,
    cs_agg.total_sales,
    cs_agg.order_cnt,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
ORDER BY cs_agg.total_sales DESC
LIMIT 100
