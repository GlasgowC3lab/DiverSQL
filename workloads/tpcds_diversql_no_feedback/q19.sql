WITH sales_cc AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_sold_date_sk,
    cs.cs_call_center_sk,
    d.d_year,
    d.d_day_name,
    cc.cc_name,
    cc.cc_city
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 1915
    AND regexp_like(cc.cc_name, 'Center')
    AND d.d_day_name LIKE '%day%'
),
store_arrays AS (
  SELECT
    s.s_store_sk,
    s.s_state,
    s.s_county,
    ARRAY[s.s_state, s.s_county] AS attr_arr,
    d.d_year
  FROM store s
  JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  WHERE d.d_year = 1915
),
unnest_store AS (
  SELECT
    sa.s_store_sk,
    t.attr
  FROM store_arrays sa
  CROSS JOIN UNNEST(sa.attr_arr) AS t(attr)
),
month_vals AS (
  SELECT month_name FROM (VALUES 'Jan', 'Feb', 'Mar') AS t(month_name)
)
SELECT
  sc.cc_name,
  substring(sc.cc_city, 1, 3) AS city_prefix,
  sc.d_day_name,
  SUM(sc.cs_net_profit) AS total_profit,
  us.attr AS store_attribute,
  mv.month_name
FROM sales_cc sc
CROSS JOIN unnest_store us
CROSS JOIN month_vals mv
WHERE regexp_extract(sc.cc_city, '[A-Za-z]+') IS NOT NULL
GROUP BY
  sc.cc_name,
  substring(sc.cc_city, 1, 3),
  sc.d_day_name,
  us.attr,
  mv.month_name
ORDER BY total_profit DESC
LIMIT 100
