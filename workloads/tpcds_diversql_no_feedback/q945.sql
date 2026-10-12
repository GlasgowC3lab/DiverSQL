WITH
  sales_cte AS (
    SELECT
      w.w_warehouse_name,
      cp.cp_catalog_page_number,
      SUM(cs.cs_net_profit) AS amount,
      'sales' AS source_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
      AND i.i_manufact = 'barcallyable'
    GROUP BY w.w_warehouse_name, cp.cp_catalog_page_number
  ),
  returns_cte AS (
    SELECT
      w.w_warehouse_name,
      cp.cp_catalog_page_number,
      SUM(cr.cr_net_loss) AS amount,
      'returns' AS source_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450500
      AND i.i_manufact = 'barcallyable'
    GROUP BY w.w_warehouse_name, cp.cp_catalog_page_number
  )
SELECT
  combined.w_warehouse_name,
  combined.cp_catalog_page_number,
  combined.amount,
  combined.source_type,
  ROW_NUMBER() OVER (ORDER BY combined.amount DESC) AS row_num
FROM (
  SELECT * FROM sales_cte
  UNION ALL
  SELECT * FROM returns_cte
) AS combined
ORDER BY combined.amount DESC, combined.source_type
LIMIT 100
