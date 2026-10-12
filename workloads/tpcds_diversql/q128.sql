WITH base AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_bill_cdemo_sk,
    ws.ws_bill_addr_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_site_sk,
    ws.ws_order_number
  FROM web_sales ws
  WHERE ws.ws_quantity > 5
    AND ws.ws_net_paid > 0
),

sold_date AS (
  SELECT
    b.*,
    d.d_year,
    d.d_date
  FROM base b
  JOIN date_dim d ON b.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_current_month = 'Y'
),

call_cte AS (
  SELECT
    sd.*,
    cc.cc_name,
    cc.cc_employees,
    cc.cc_gmt_offset
  FROM sold_date sd
  JOIN call_center cc ON cc.cc_open_date_sk = sd.ws_sold_date_sk
  WHERE cc.cc_employees > 50
    AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
),

warehouse_cte AS (
  SELECT
    ct.*,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    w.w_country
  FROM call_cte ct
  JOIN warehouse w ON ct.ws_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_country = 'United States'
    AND w.w_warehouse_sq_ft > 500000
),

site_cte AS (
  SELECT
    wc.*,
    s.web_name,
    s.web_tax_percentage
  FROM warehouse_cte wc
  JOIN web_site s ON wc.ws_web_site_sk = s.web_site_sk
  WHERE s.web_tax_percentage > 5.0
),

address_cte AS (
  SELECT
    sc.*,
    ca.ca_state,
    ca.ca_city
  FROM site_cte sc
  JOIN customer_address ca ON sc.ws_bill_addr_sk = ca.ca_address_sk
  WHERE ca.ca_state = 'CA'
),

demo_cte AS (
  SELECT
    a.*,
    cd.cd_gender,
    cd.cd_education_status
  FROM address_cte a
  JOIN customer_demographics cd ON a.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'
),

agg1 AS (
  SELECT
    cc_name,
    d_year,
    SUM(ws_net_paid) AS total_sales,
    SUM(ws_quantity) AS total_qty
  FROM demo_cte
  GROUP BY cc_name, d_year
),

agg2 AS (
  SELECT
    d_year,
    AVG(total_sales) AS avg_sales_per_center,
    AVG(total_qty) AS avg_qty_per_center
  FROM agg1
  GROUP BY d_year
),

topk AS (
  SELECT
    a1.*,
    ROW_NUMBER() OVER (PARTITION BY a1.d_year ORDER BY a1.total_sales DESC) AS rn
  FROM agg1 a1
),

filtered_topk AS (
  SELECT
    t.*, 
    ARRAY[CAST(t.total_sales AS decimal(20,2)), CAST(t.total_qty AS decimal(20,2))] AS metrics_arr
  FROM topk t
  WHERE t.rn <= 3
),

unnested AS (
  SELECT
    ft.d_year,
    ft.cc_name,
    ft.total_sales,
    ft.total_qty,
    m.metric_index,
    m.metric_value
  FROM filtered_topk ft
  CROSS JOIN UNNEST(ft.metrics_arr) WITH ORDINALITY AS m(metric_value, metric_index)
),

call_names_sales AS (
  SELECT cc_name FROM agg1 WHERE total_sales > 100000
),

call_names_qty AS (
  SELECT cc_name FROM agg1 WHERE total_qty > 1000
),

intersect_names AS (
  SELECT cc_name FROM call_names_sales
  INTERSECT
  SELECT cc_name FROM call_names_qty
)

SELECT
  u.d_year,
  u.cc_name,
  u.total_sales,
  u.total_qty,
  u.metric_index,
  u.metric_value,
  a2.avg_sales_per_center,
  a2.avg_qty_per_center
FROM unnested u
JOIN agg2 a2 ON u.d_year = a2.d_year
WHERE u.cc_name IN (SELECT cc_name FROM intersect_names)
ORDER BY u.d_year, u.total_sales DESC
LIMIT 10
