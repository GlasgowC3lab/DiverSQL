SELECT *
FROM (
  SELECT
    promo_name,
    state,
    total_sales,
    CASE WHEN total_sales > 20000 THEN 'High' ELSE 'Low' END AS sales_category,
    RANK() OVER (PARTITION BY state ORDER BY total_sales DESC) AS state_rank
  FROM (
    SELECT
      p.p_promo_name AS promo_name,
      ca_bill.ca_state AS state,
      SUM(cs.cs_net_paid_inc_ship) AS total_sales
    FROM catalog_sales cs
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_net_paid_inc_ship > 500
      AND p.p_channel_demo = 'N'
      AND ca_bill.ca_zip LIKE '12%'
    GROUP BY ROLLUP (p.p_promo_name, ca_bill.ca_state)
  ) a
  UNION DISTINCT
  SELECT
    promo_name,
    state,
    total_sales,
    CASE WHEN total_sales > 20000 THEN 'High' ELSE 'Low' END AS sales_category,
    RANK() OVER (PARTITION BY state ORDER BY total_sales DESC) AS state_rank
  FROM (
    SELECT
      p.p_promo_name AS promo_name,
      ca_ship.ca_state AS state,
      SUM(cs.cs_net_paid_inc_ship) AS total_sales
    FROM catalog_sales cs
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_ext_wholesale_cost > 1500
      AND cs.cs_net_paid_inc_ship > 1000
      AND p.p_channel_details LIKE '%family%'
      AND ca_ship.ca_zip LIKE '68%'
    GROUP BY ROLLUP (p.p_promo_name, ca_ship.ca_state)
  ) b
) final_result
ORDER BY total_sales DESC
LIMIT 100
