WITH
  cs_data AS (
    SELECT
      c.c_customer_id AS customer_id,
      cs.cs_net_paid AS net_paid,
      p.p_discount_active,
      w.w_state,
      inv.inv_quantity_on_hand,
      cc.cc_market_manager,
      cp.cp_department,
      sm.sm_type,
      t.t_hour
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND w.w_country = 'United States'
      AND cc.cc_market_manager = 'John Doe'
  ),
  ss_data AS (
    SELECT
      c.c_customer_id AS customer_id,
      ss.ss_net_paid AS net_paid,
      s.s_state,
      t.t_hour,
      p.p_discount_active,
      ca.ca_city
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 10 AND 16
      AND p.p_discount_active = 'Y'
  ),
  sr_data AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      s.s_store_name,
      t.t_hour,
      ss.ss_customer_sk
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
  ),
  wr_data AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      t.t_hour
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 18
  ),
  inv_data AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      w.w_warehouse_sk,
      w.w_state
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
  ),
  sales_customers AS (
    SELECT DISTINCT customer_id FROM cs_data
    UNION
    SELECT DISTINCT customer_id FROM ss_data
  ),
  return_customers AS (
    SELECT DISTINCT c.c_customer_id AS customer_id
    FROM sr_data sr
    JOIN customer c ON sr.ss_customer_sk = c.c_customer_sk
  ),
  final_customers AS (
    SELECT customer_id FROM sales_customers
    EXCEPT
    SELECT customer_id FROM return_customers
  ),
  customer_profit AS (
    SELECT
      customer_id,
      SUM(net_paid) AS total_net_paid
    FROM (
      SELECT customer_id, net_paid FROM cs_data
      UNION ALL
      SELECT customer_id, net_paid FROM ss_data
    ) cp
    GROUP BY customer_id
  )
SELECT
  fc.customer_id,
  cp.total_net_paid,
  RANK() OVER (ORDER BY cp.total_net_paid DESC) AS profit_rank,
  CASE
    WHEN cp.total_net_paid > (SELECT AVG(total_net_paid) FROM customer_profit) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS performance,
  ROW_NUMBER() OVER (ORDER BY cp.total_net_paid DESC) AS row_num
FROM final_customers fc
JOIN customer_profit cp ON fc.customer_id = cp.customer_id
ORDER BY profit_rank
LIMIT 100
