WITH
  sr_agg AS (
    SELECT
      sr_returned_date_sk AS d_date_sk,
      SUM(sr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001 AND d_quarter_name = '2001Q1'
    )
    GROUP BY sr_returned_date_sk
  ),

  cs_agg AS (
    SELECT
      cs_sold_date_sk AS d_date_sk,
      SUM(cs_net_paid) AS total_net_paid,
      AVG(cs_ext_discount_amt) AS avg_discount,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 500
      AND cs_ext_ship_cost < 2000
    GROUP BY cs_sold_date_sk
  ),

  intersect_orders AS (
    SELECT cs_order_number AS order_key
    FROM catalog_sales
    WHERE cs_ship_mode_sk = (
      SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'FEDEX' LIMIT 1
    )
    INTERSECT
    SELECT sr_ticket_number AS order_key
    FROM store_returns
    WHERE sr_fee > 0
  ),

  full_cp_cs AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      cp.cp_catalog_number,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_ext_discount_amt,
      cs.cs_sold_date_sk AS sold_date_sk,
      cs.cs_ext_sales_price,
      sm.sm_type,
      sm.sm_carrier,
      CASE WHEN sm.sm_type = 'EXPRESS' THEN cs.cs_ext_sales_price ELSE 0 END AS express_sales
    FROM catalog_page cp
    FULL OUTER JOIN catalog_sales cs
      ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    LEFT JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  ),

  joined AS (
    SELECT
      d.d_year,
      d.d_quarter_name,
      fp.cp_department,
      fp.cs_net_paid,
      fp.express_sales,
      fp.cs_order_number,
      fp.sm_carrier,
      sr.total_net_loss,
      cs.total_net_paid AS agg_total_net_paid
    FROM full_cp_cs fp
    JOIN date_dim d
      ON fp.sold_date_sk = d.d_date_sk
    LEFT JOIN sr_agg sr
      ON d.d_date_sk = sr.d_date_sk
    LEFT JOIN cs_agg cs
      ON d.d_date_sk = cs.d_date_sk
    LEFT JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND fp.sm_carrier = 'FEDEX'
      AND fp.cp_department IN ('Books', 'Electronics')
      AND fp.cs_order_number IN (SELECT order_key FROM intersect_orders)
  ),

  agg AS (
    SELECT
      d_year,
      d_quarter_name,
      cp_department,
      SUM(cs_net_paid) AS sum_net_paid,
      SUM(express_sales) AS sum_express_sales,
      MAX(total_net_loss) AS max_net_loss,
      AVG(agg_total_net_paid) AS avg_agg_total_net_paid,
      COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM joined
    GROUP BY
      d_year,
      d_quarter_name,
      cp_department,
      total_net_loss,
      agg_total_net_paid
    HAVING SUM(cs_net_paid) > 10000
  )
SELECT
  d_year,
  d_quarter_name,
  cp_department,
  sum_net_paid,
  sum_express_sales,
  max_net_loss,
  avg_agg_total_net_paid,
  distinct_orders
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_net_paid DESC) AS rn
  FROM agg
) t
WHERE rn <= 5
ORDER BY d_year, sum_net_paid DESC
LIMIT 100
