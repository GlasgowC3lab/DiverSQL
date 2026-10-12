WITH
store_sales_agg AS (
  SELECT
    s.s_state AS state,
    s.s_city AS city,
    sum(ss.ss_net_paid) AS net_paid,
    sum(ss.ss_net_profit) AS net_profit,
    count(DISTINCT ss.ss_ticket_number) AS orders,
    max(d.d_date) AS max_date,
    CAST(0 AS integer) AS promo_active_orders
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_state, s.s_city
),
catalog_sales_agg AS (
  SELECT
    cc.cc_state AS state,
    cc.cc_city AS city,
    sum(cs.cs_net_paid) AS net_paid,
    sum(cs.cs_net_profit) AS net_profit,
    count(DISTINCT cs.cs_order_number) AS orders,
    max(d.d_date) AS max_date,
    CAST(0 AS integer) AS promo_active_orders
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY cc.cc_state, cc.cc_city
),
web_sales_agg AS (
  SELECT
    wsit.web_state AS state,
    wsit.web_city AS city,
    sum(ws.ws_net_paid) AS net_paid,
    sum(ws.ws_net_profit) AS net_profit,
    count(DISTINCT ws.ws_order_number) AS orders,
    max(d.d_date) AS max_date,
    sum(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_orders
  FROM web_sales ws
  LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY wsit.web_state, wsit.web_city
),
combined_sales AS (
  SELECT state, city, net_paid, net_profit, orders, max_date, promo_active_orders FROM store_sales_agg
  UNION ALL
  SELECT state, city, net_paid, net_profit, orders, max_date, promo_active_orders FROM catalog_sales_agg
  UNION ALL
  SELECT state, city, net_paid, net_profit, orders, max_date, promo_active_orders FROM web_sales_agg
),
sales_summary AS (
  SELECT
    state,
    city,
    sum(net_paid) AS total_net_paid,
    sum(net_profit) AS total_net_profit,
    sum(orders) AS total_orders,
    max(max_date) AS latest_sale_date,
    sum(promo_active_orders) AS total_active_promos
  FROM combined_sales
  GROUP BY state, city
),
customer_last_purchase AS (
  SELECT
    c.c_customer_sk,
    max(d.d_date) AS last_purchase_date,
    sum(
      coalesce(ss.ss_net_paid, 0) +
      coalesce(cs.cs_net_paid, 0) +
      coalesce(ws.ws_net_paid, 0)
    ) AS total_spent
  FROM customer c
  LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
  LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
  LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
  LEFT JOIN date_dim d ON d.d_date_sk = coalesce(ss.ss_sold_date_sk, cs.cs_sold_date_sk, ws.ws_sold_date_sk)
  GROUP BY c.c_customer_sk
),
final AS (
  SELECT
    ss.state,
    ss.city,
    ss.total_net_paid,
    ss.total_net_profit,
    ss.total_orders,
    ss.latest_sale_date,
    ss.total_active_promos,
    rank() OVER (PARTITION BY ss.state ORDER BY ss.total_net_profit DESC) AS profit_rank_state,
    CASE
      WHEN ss.total_net_profit > 0 THEN 'POSITIVE'
      WHEN ss.total_net_profit < 0 THEN 'NEGATIVE'
      ELSE 'ZERO'
    END AS profit_indicator,
    concat(ss.city, ', ', ss.state) AS location_key,
    (SELECT count(*) FROM customer_last_purchase clp
     WHERE clp.last_purchase_date >= ss.latest_sale_date - INTERVAL '30' DAY) AS recent_active_customers
  FROM sales_summary ss
  WHERE ss.total_net_paid IS NOT NULL
)
SELECT *
FROM final
WHERE profit_rank_state <= 10
ORDER BY state, profit_rank_state
