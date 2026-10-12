WITH
  sales_base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_ship_date_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_item_sk,
      cs.cs_ext_wholesale_cost,
      cs.cs_net_paid_inc_tax,
      cs.cs_net_profit,
      -- build a small array that we will UNNEST later
      ARRAY[cs.cs_ship_mode_sk, cs.cs_item_sk] AS dim_array
    FROM tpcds.catalog_sales cs
  ),
  joined1 AS (
    SELECT
      sb.*,
      td.t_am_pm,
      td.t_shift,
      cp.cp_department,
      cp.cp_catalog_number,
      sm.sm_type,
      sm.sm_code,
      it.i_category,
      it.i_brand,
      u.element AS dim_element
    FROM sales_base sb
    JOIN tpcds.time_dim td
      ON sb.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.catalog_page cp
      ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
      ON sb.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.item it
      ON sb.cs_item_sk = it.i_item_sk
    CROSS JOIN UNNEST(sb.dim_array) AS u (element)
  ),
  joined2 AS (
    SELECT
      j1.*,
      cp2.cp_type AS cp2_type
    FROM joined1 j1
    JOIN tpcds.catalog_page cp2
      ON j1.cs_catalog_page_sk = cp2.cp_catalog_page_sk
  ),
  joined3 AS (
    SELECT
      j2.*,
      sm2.sm_contract AS sm2_contract
    FROM joined2 j2
    JOIN tpcds.ship_mode sm2
      ON j2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
  ),
  joined4 AS (
    SELECT
      j3.*,
      td2.t_meal_time
    FROM joined3 j3
    JOIN tpcds.time_dim td2
      ON j3.cs_sold_time_sk = td2.t_time_sk
  ),
  joined5 AS (
    SELECT
      j4.*,
      it2.i_color AS it2_color
    FROM joined4 j4
    JOIN tpcds.item it2
      ON j4.cs_item_sk = it2.i_item_sk
  ),
  full_join AS (
    SELECT
      j5.cs_sold_date_sk,
      j5.cp_department        AS cp_department,
      j5.sm_type,
      j5.i_category,
      j5.t_am_pm,
      j5.dim_element,
      j5.cs_net_profit,
      j5.cs_ext_wholesale_cost,
      CASE
        WHEN j5.cs_net_profit > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
      END                     AS profit_flag
    FROM joined5 j5
    FULL OUTER JOIN tpcds.catalog_page cp_full
      ON j5.cs_catalog_page_sk = cp_full.cp_catalog_page_sk
  )
SELECT
  profit_flag,
  cp_department,
  sm_type,
  i_category,
  t_am_pm,
  COUNT(*)                     AS order_cnt,
  SUM(cs_net_profit)           AS total_profit,
  AVG(cs_ext_wholesale_cost)   AS avg_wholesale_cost
FROM full_join
WHERE EXISTS (
  SELECT 1
  FROM tpcds.ship_mode sm_check
  WHERE sm_check.sm_type = full_join.sm_type
    AND sm_check.sm_contract = 'HVDFCcQ'
)
GROUP BY
  profit_flag,
  cp_department,
  sm_type,
  i_category,
  t_am_pm
ORDER BY total_profit DESC
LIMIT 100
