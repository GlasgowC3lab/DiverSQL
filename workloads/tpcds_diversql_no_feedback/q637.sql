WITH sales_base AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_addr_sk,
        cs.cs_net_paid,
        cs.cs_coupon_amt,
        cs.cs_list_price,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_item_sk,
        d.d_year,
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        sm.sm_type,
        ca.ca_state,
        i.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND sm.sm_contract = 'ldhM8IvpzHgdbBgDfI'
      AND d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND ca.ca_state = 'TX'
      AND cs.cs_coupon_amt > 500
      AND cs.cs_list_price BETWEEN 100 AND 200
      AND i.inv_quantity_on_hand >= 50
      AND EXISTS (
          SELECT 1 FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm2.sm_type = 'EXPRESS'
      )
)
SELECT
    w_warehouse_name,
    sm_ship_mode_id,
    d_year,
    ca_state,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_coupon_amt) AS avg_coupon_amt,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_ext_sales_price) AS min_ext_sales_price,
    MAX(cs_quantity) AS max_quantity
FROM sales_base
GROUP BY w_warehouse_name, sm_ship_mode_id, d_year, ca_state
HAVING SUM(cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
