WITH
  -- Items that appear in catalog sales but not in store sales
  item_diff AS (
    SELECT i.i_item_id
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    EXCEPT
    SELECT i2.i_item_id
    FROM store_sales ss
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  ),
  -- Small dimension for cross join
  small_brands AS (
    SELECT DISTINCT i_brand
    FROM item
    LIMIT 5
  ),
  -- Small set of numbers for cross join
  numbers AS (
    SELECT * FROM (VALUES 1, 2, 3) AS t(num)
  ),
  -- Central join that brings together all 13 tables
  joined_all AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price,
      i.i_item_id,
      i.i_brand,
      i.i_category,
      cc.cc_hours,
      cc.cc_state,
      cp.cp_department,
      sm.sm_type,
      w.w_warehouse_name,
      cust.c_customer_sk,
      cust.c_last_name,
      addr.ca_state,
      ss.ss_quantity,
      sr.sr_return_quantity,
      ws.ws_quantity,
      wp.wp_type,
      webs.web_name,
      pt.price_w_tax,
      u.hour_part,
      sb.i_brand AS sb_brand,
      n.num
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address addr ON cs.cs_bill_addr_sk = addr.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = cust.c_customer_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = cust.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
    CROSS JOIN LATERAL (SELECT i.i_current_price * 1.07 AS price_w_tax) AS pt
    CROSS JOIN LATERAL (SELECT split(cc.cc_hours, '-') AS hrs) AS a
    CROSS JOIN UNNEST(a.hrs) AS u(hour_part)
    CROSS JOIN small_brands sb
    CROSS JOIN numbers n
  ),
  -- Union two filtered slices to force de‑duplication
  unioned AS (
    SELECT
      i_brand,
      hour_part,
      cs_ext_sales_price AS sales_amount,
      COALESCE(ss_quantity, 0) + COALESCE(ws_quantity, 0) AS total_qty
    FROM joined_all
    WHERE cc_state = 'CA'
    UNION DISTINCT
    SELECT
      i_brand,
      hour_part,
      cs_ext_sales_price AS sales_amount,
      COALESCE(ss_quantity, 0) + COALESCE(ws_quantity, 0) AS total_qty
    FROM joined_all
    WHERE cc_state = 'NY'
  )
SELECT
  brand,
  hour_part,
  SUM(sales_amount)      AS total_sales,
  SUM(total_qty)         AS total_quantity,
  COUNT(*)               AS rows_cnt,
  (SELECT COUNT(*) FROM item_diff) AS diff_item_cnt
FROM (
  SELECT
    i_brand AS brand,
    hour_part,
    sales_amount,
    total_qty
  FROM unioned
  WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = (
          SELECT c_customer_sk
          FROM customer
          WHERE c_last_name = 'Norman'
          LIMIT 1
        )
      AND sr2.sr_return_amt > 0
  )
) agg
GROUP BY brand, hour_part
ORDER BY total_sales DESC
LIMIT 100
