WITH
  /* Base fact with star joins to all dimensions and other fact tables */
  base_sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      td_sales.t_hour,
      i.i_item_id,
      i.i_product_name,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type,
      cd.cd_gender,
      ca.ca_city,
      p.p_promo_name,
      -- web sales fields (optional, may be null)
      ws.ws_web_site_sk,
      ws.ws_ship_date_sk,
      -- catalog returns (anti‑join) – kept as LEFT JOIN so we can filter on NULL
      cr.cr_order_number,
      td_return.t_hour AS return_hour,
      r_return.r_reason_desc AS return_reason_desc,
      -- store returns (optional, may be null)
      sr.sr_return_quantity,
      td_store_ret.t_hour AS store_return_hour,
      r_store.r_reason_desc AS store_return_reason_desc,
      s.s_store_name,
      ws_site.web_name
    FROM catalog_sales cs
    INNER JOIN time_dim td_sales
      ON cs.cs_sold_time_sk = td_sales.t_time_sk
    INNER JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    /* Optional web sales link – same item and same sold time */
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = cs.cs_item_sk
     AND ws.ws_sold_time_sk = cs.cs_sold_time_sk
    LEFT JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    /* LEFT JOIN catalog_returns for anti‑join logic */
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN time_dim td_return
      ON cr.cr_returned_time_sk = td_return.t_time_sk
    LEFT JOIN reason r_return
      ON cr.cr_reason_sk = r_return.r_reason_sk
    /* LEFT JOIN store_returns – uses the same item and time dimension */
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_return_time_sk = td_sales.t_time_sk
    LEFT JOIN time_dim td_store_ret
      ON sr.sr_return_time_sk = td_store_ret.t_time_sk
    LEFT JOIN reason r_store
      ON sr.sr_reason_sk = r_store.r_reason_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    WHERE cr.cr_order_number IS NULL  -- anti‑join: keep sales with no catalog return
  ),

  /* Aggregate per item / channel / demographic slice */
  agg_sales AS (
    SELECT
      i_item_id,
      cc_name,
      cp_department,
      sm_type,
      cd_gender,
      ca_city,
      SUM(cs_net_paid)   AS total_net_paid,
      SUM(cs_quantity)   AS total_quantity,
      COUNT(*)           AS sales_cnt,
      MIN(cs_sold_date_sk) AS first_sold_date_sk,
      MAX(cs_sold_date_sk) AS last_sold_date_sk
    FROM base_sales
    GROUP BY
      i_item_id,
      cc_name,
      cp_department,
      sm_type,
      cd_gender,
      ca_city
  )

SELECT
  i_item_id,
  cc_name,
  cp_department,
  sm_type,
  cd_gender,
  ca_city,
  total_net_paid,
  total_quantity,
  sales_cnt,
  ROW_NUMBER() OVER (ORDER BY total_net_paid DESC)                           AS row_num,
  LAG(total_net_paid) OVER (PARTITION BY i_item_id ORDER BY total_net_paid DESC) AS lag_total_net_paid,
  SUM(total_net_paid) OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_by_center
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
