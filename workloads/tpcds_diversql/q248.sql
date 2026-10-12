WITH
  base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      cc.cc_name,
      cc.cc_manager,
      c.c_birth_country,
      d_sold.d_year AS sold_year,
      d_ship.d_year AS ship_year,
      wp.wp_type,
      wp.wp_max_ad_count
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.date_dim d_creation
      ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN tpcds.date_dim d_access
      ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN tpcds.call_center cc
      ON cc.cc_closed_date_sk = d_ship.d_date_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND cc.cc_employees > 1000000
  ),

  order_intersect AS (
    SELECT ws_order_number FROM base WHERE ws_net_profit > 1000
    INTERSECT
    SELECT ws_order_number FROM base WHERE ws_ext_sales_price > 5000
  ),

  union_set AS (
    SELECT
      ws_order_number,
      ws_net_profit,
      cc_name,
      c_birth_country,
      sold_year,
      wp_type
    FROM base
    WHERE wp_type = 'home'
      AND ws_order_number IN (SELECT ws_order_number FROM order_intersect)

    UNION  -- DISTINCT UNION

    SELECT
      ws_order_number,
      ws_net_profit,
      cc_name,
      c_birth_country,
      sold_year,
      wp_type
    FROM base
    WHERE wp_type = 'product'
      AND ws_order_number IN (SELECT ws_order_number FROM order_intersect)
  )

SELECT
  cc_name,
  c_birth_country,
  sold_year,
  SUM(ws_net_profit) AS total_net_profit,
  COUNT(*) AS order_count
FROM union_set
WHERE ws_net_profit > (
      SELECT avg(ws_net_profit) FROM tpcds.web_sales
    )
GROUP BY GROUPING SETS (
  (cc_name, sold_year),
  (c_birth_country, sold_year),
  ()
)
ORDER BY total_net_profit DESC
LIMIT 100
