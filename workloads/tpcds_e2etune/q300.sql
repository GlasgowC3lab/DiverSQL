WITH city_income_sales AS (
  SELECT
    ca_bill.ca_state,
    ca_bill.ca_city,
    ib.ib_income_band_sk,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
  FROM web_sales ws
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN income_band ib
    ON ws.ws_wholesale_cost BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
  WHERE ca_bill.ca_state IN ('AZ', 'NM', 'PA')
    AND ca_ship.ca_state = ca_bill.ca_state
    AND wp.wp_type = 'Home'
    AND ws.ws_quantity > 0
  GROUP BY ca_bill.ca_state, ca_bill.ca_city, ib.ib_income_band_sk
),
city_sales_agg AS (
  SELECT
    ca_state,
    ca_city,
    SUM(total_net_paid) AS total_net_paid,
    SUM(total_net_profit) AS total_net_profit,
    SUM(total_discount) AS total_discount,
    SUM(distinct_pages) AS distinct_pages
  FROM city_income_sales
  GROUP BY ca_state, ca_city
),
ranked_cities AS (
  SELECT
    ca_state,
    ca_city,
    total_net_paid,
    total_net_profit,
    total_discount,
    distinct_pages,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC) AS city_rank
  FROM city_sales_agg
)
SELECT
  ca_state,
  ca_city,
  total_net_paid,
  total_net_profit,
  total_discount,
  distinct_pages,
  city_rank
FROM ranked_cities
WHERE city_rank <= 5
ORDER BY ca_state, city_rank
