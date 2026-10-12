SELECT
  store_id,
  store_name,
  city,
  state,
  store_closed_year,
  sold_year,
  ship_year,
  access_year,
  wp_url,
  wp_type,
  total_net_paid,
  total_net_profit,
  distinct_orders,
  RANK() OVER (PARTITION BY store_id ORDER BY total_net_profit DESC) AS profit_rank
FROM (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    s.s_city AS city,
    s.s_state AS state,
    d_store.d_year AS store_closed_year,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    d_access.d_year AS access_year,
    wp.wp_url,
    wp.wp_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
  JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d_ship.d_date_sk
  JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
  WHERE cs.cs_quantity > 0
    AND s.s_state = 'CA'
  GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_year,
    d_sold.d_year,
    d_ship.d_year,
    d_access.d_year,
    wp.wp_url,
    wp.wp_type
) AS agg
ORDER BY total_net_profit DESC
LIMIT 100
