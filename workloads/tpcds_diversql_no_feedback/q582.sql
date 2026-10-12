WITH
  avg_qty AS (
    SELECT AVG(cs_quantity) AS val
    FROM catalog_sales
  ),

  base AS (
    SELECT
      d.d_year,
      d.d_quarter_name,
      p.p_promo_name,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      ws.ws_order_number,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      cr.cr_return_quantity,
      wr.wr_return_quantity,
      inv.inv_quantity_on_hand,
      r.r_reason_desc,
      cc2.cc_state,
      CASE WHEN cs.cs_quantity > (SELECT val FROM avg_qty) THEN 1 ELSE 0 END AS qty_above_avg_flag
    FROM store_sales ss
    RIGHT OUTER JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc2
      ON cs.cs_call_center_sk = cc2.cc_call_center_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_name = '2001Q1'
      AND cc2.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
      AND r.r_reason_desc LIKE '%warranty%'
  ),

  agg AS (
    SELECT
      d_year,
      d_quarter_name,
      p_promo_name,
      SUM(cs_ext_sales_price) AS total_catalog_sales,
      SUM(ws_ext_sales_price) AS total_web_sales,
      COUNT(DISTINCT cs_order_number) AS catalog_orders,
      COUNT(DISTINCT ws_order_number) AS web_orders,
      SUM(CASE WHEN qty_above_avg_flag = 1 THEN cs_quantity ELSE 0 END) AS qty_above_avg_sum
    FROM base
    GROUP BY d_year, d_quarter_name, p_promo_name
  )

SELECT
  d_year,
  d_quarter_name,
  p_promo_name,
  total_catalog_sales,
  total_web_sales,
  catalog_orders,
  web_orders,
  qty_above_avg_sum
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales + total_web_sales DESC) AS rn
  FROM agg
) ranked
WHERE rn <= 3
ORDER BY total_catalog_sales DESC
LIMIT 10
