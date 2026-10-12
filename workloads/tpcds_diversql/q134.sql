WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cc.cc_company,
    cp.cp_department,
    w.w_warehouse_name,
    i.i_category,
    i.i_current_price,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ca.ca_state,
    inv.inv_quantity_on_hand,
    ss.ss_quantity,
    st.s_store_name,
    sr.sr_return_quantity,
    cr.cr_return_amount,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN store st ON ss.ss_store_sk = st.s_store_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
  WHERE cc.cc_company = 3
    AND cc.cc_manager = 'Larry Mccray'
    AND hd.hd_buy_potential = '5001-10000'
    AND inv.inv_quantity_on_hand > 0
    AND st.s_state = 'CA'
    AND cc.cc_rec_start_date >= DATE '2001-01-01'
    AND cc.cc_rec_end_date <= DATE '2005-12-31'
),
agg1 AS (
  SELECT
    i_category,
    profit_flag,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS txn_count
  FROM base
  GROUP BY i_category, profit_flag
)
SELECT
  i_category,
  profit_flag,
  total_sales,
  total_profit,
  txn_count,
  total_profit / NULLIF(txn_count, 0) AS avg_profit_per_txn,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM agg1
ORDER BY total_profit DESC
LIMIT 100
