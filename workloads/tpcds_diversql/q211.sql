WITH store_agg AS (
  SELECT
    s.s_store_name,
    ca.ca_state,
    i.i_item_id,
    i.i_current_price,
    SUM(ss.ss_net_profit) AS total_profit
  FROM tpcds.store_sales ss
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.inventory inv ON i.i_item_sk = inv.inv_item_sk
  JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN tpcds.web_returns wr ON i.i_item_sk = wr.wr_item_sk
  LEFT JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_current_price BETWEEN 10 AND 100
    AND ca.ca_state = 'CA'
    AND s.s_gmt_offset > -5
  GROUP BY s.s_store_name, ca.ca_state, i.i_item_id, i.i_current_price
),
store_ranked AS (
  SELECT
    'Store' AS category,
    s_store_name AS entity,
    ca_state AS state,
    i_item_id AS item_id,
    CASE WHEN i_current_price > 50 THEN 'High' ELSE 'Low' END AS price_category,
    total_profit AS total_amount,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_profit DESC) AS rank_val
  FROM store_agg
),
catalog_agg AS (
  SELECT
    r.r_reason_desc,
    ca.ca_state,
    i.i_item_id,
    i.i_current_price,
    SUM(cr.cr_return_amount) AS total_return
  FROM tpcds.catalog_sales cs
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN tpcds.inventory inv ON i.i_item_sk = inv.inv_item_sk
  JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN tpcds.catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_current_price BETWEEN 10 AND 100
    AND ca.ca_state = 'CA'
    AND cc.cc_state = 'CA'
    AND cp.cp_department = 'Sports'
    AND r.r_reason_desc LIKE '%size%'
  GROUP BY r.r_reason_desc, ca.ca_state, i.i_item_id, i.i_current_price
),
catalog_ranked AS (
  SELECT
    'CatalogReturn' AS category,
    r_reason_desc AS entity,
    ca_state AS state,
    i_item_id AS item_id,
    CASE WHEN i_current_price > 50 THEN 'High' ELSE 'Low' END AS price_category,
    total_return AS total_amount,
    DENSE_RANK() OVER (ORDER BY total_return DESC) AS rank_val
  FROM catalog_agg
)
SELECT DISTINCT *
FROM (
  SELECT * FROM store_ranked
  UNION
  SELECT * FROM catalog_ranked
) AS final_result
ORDER BY rank_val
LIMIT 100
