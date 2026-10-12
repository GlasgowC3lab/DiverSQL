WITH
  -- Aggregate catalog sales per item and call center, include demographic income band
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      i.i_product_name,
      cc.cc_call_center_id,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
      COUNT(*) AS catalog_order_cnt,
      SUM(cs.cs_quantity) AS catalog_qty,
      SUM(cs.cs_net_profit) AS catalog_profit,
      hd.hd_income_band_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_sales_price > 30
      AND cc.cc_state = 'CA'
      AND i.i_color = 'Red'
    GROUP BY cs.cs_item_sk, i.i_product_name, cc.cc_call_center_id, hd.hd_income_band_sk
  ),
  -- Aggregate web sales per item and web page, include demographic income band via join to household_demographics (through web_sales)
  web_sales_agg AS (
    SELECT
      ws.ws_item_sk,
      i.i_product_name,
      ws.ws_web_page_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      COUNT(*) AS web_order_cnt,
      SUM(ws.ws_quantity) AS web_qty,
      SUM(ws.ws_net_profit) AS web_profit,
      hd.hd_income_band_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_quantity > 2
      AND ws.ws_sales_price > 30
      AND wsite.web_state = 'CA'
      AND i.i_color = 'Red'
      AND wp.wp_type = 'content'
    GROUP BY ws.ws_item_sk, i.i_product_name, ws.ws_web_page_sk, hd.hd_income_band_sk
  ),
  -- Total quantity on hand per item
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.inventory inv
    GROUP BY inv.inv_item_sk
  ),
  -- Total return amount per item
  returns_agg AS (
    SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM tpcds.web_returns wr
    GROUP BY wr.wr_item_sk
  ),
  -- Items that appear in catalog sales but not in web sales
  items_only_catalog AS (
    SELECT cs_item_sk FROM sales_agg
    EXCEPT
    SELECT ws_item_sk FROM web_sales_agg
  ),
  -- Combine all aggregates, keep only items that are in the EXCEPT set
  combined AS (
    SELECT
      s.cs_item_sk AS item_sk,
      s.i_product_name,
      s.cc_call_center_id,
      s.catalog_sales_total,
      w.web_sales_total,
      inv.total_on_hand,
      COALESCE(r.total_return_amt, 0) AS total_return_amt,
      ib.ib_upper_bound,
      wp.wp_type,
      (s.catalog_sales_total - w.web_sales_total) AS sales_diff
    FROM sales_agg s
    JOIN web_sales_agg w ON s.cs_item_sk = w.ws_item_sk
    JOIN inventory_agg inv ON s.cs_item_sk = inv.inv_item_sk
    LEFT JOIN returns_agg r ON s.cs_item_sk = r.wr_item_sk
    JOIN tpcds.income_band ib ON s.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_page wp ON w.ws_web_page_sk = wp.wp_web_page_sk
    WHERE s.cs_item_sk IN (SELECT cs_item_sk FROM items_only_catalog)
      AND ib.ib_upper_bound < 80000
  ),
  -- Final aggregation to compute average sales difference
  final AS (
    SELECT
      item_sk,
      i_product_name,
      cc_call_center_id,
      catalog_sales_total,
      web_sales_total,
      total_on_hand,
      total_return_amt,
      ib_upper_bound,
      wp_type,
      sales_diff
    FROM combined
  )
SELECT
  item_sk,
  i_product_name,
  cc_call_center_id,
  catalog_sales_total,
  web_sales_total,
  total_on_hand,
  total_return_amt,
  ib_upper_bound,
  wp_type,
  sales_diff,
  ROW_NUMBER() OVER (ORDER BY sales_diff DESC) AS sales_rank
FROM final
WHERE sales_diff > (SELECT AVG(sales_diff) FROM final)
ORDER BY sales_diff DESC
LIMIT 100
