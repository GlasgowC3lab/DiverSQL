-- Goal: Identify the top items (by sales and returns) across all sales channels, ranking them within each department/category and limiting to the most relevant 100 rows.
-- The query joins all 14 selected TPC‑DS tables using only the permitted join keys, applies several filters, uses a pre‑aggregation CTE, a TABLESAMPLE, an INTERSECT, a UNION DISTINCT, window ranking, and a scalar sub‑query.
WITH
  -- Pre‑aggregate store sales per item and store (pre‑aggregation before the main joins)
  agg_store_sales AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      SUM(ss_ext_sales_price)   AS store_sales_total,
      SUM(ss_quantity)          AS store_qty
    FROM store_sales
    GROUP BY ss_item_sk, ss_store_sk
  ),

  -- Sample a fraction of the customers to keep the query lightweight
  sampled_customers AS (
    SELECT *
    FROM customer TABLESAMPLE BERNOULLI (10)
  ),

  -- Items that have both strong catalog sales and strong store returns (INTERSECT of two key sets)
  high_interest_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
    GROUP BY cs.cs_item_sk
    HAVING SUM(cs.cs_ext_sales_price) > 5000
    INTERSECT
    SELECT sr.sr_item_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 200
    GROUP BY sr.sr_item_sk
    HAVING SUM(sr.sr_return_amt) > 1000
  )

SELECT
  final.item_id,
  final.item_desc,
  final.department,
  final.warehouse_name,
  final.total_sales,
  final.total_store_activity,
  final.department_rank,
  final.source,
  final.avg_demo_purchase_estimate
FROM (
  -- First branch: catalog sales + store sales side‑by‑side
  SELECT
    i.i_item_id                                    AS item_id,
    i.i_item_desc                                 AS item_desc,
    cp.cp_department                              AS department,
    ws.w_warehouse_name                           AS warehouse_name,
    SUM(cs.cs_ext_sales_price)                    AS total_sales,
    SUM(agg.store_sales_total)                    AS total_store_activity,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS department_rank,
    'CATALOG'                                    AS source,
    (SELECT AVG(cd2.cd_purchase_estimate) FROM customer_demographics cd2) AS avg_demo_purchase_estimate
  FROM sampled_customers c
  JOIN customer_address ca          ON c.c_current_addr_sk   = ca.ca_address_sk
  JOIN customer_demographics cd     ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN catalog_sales cs            ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN catalog_page cp             ON cs.cs_catalog_page_sk  = cp.cp_catalog_page_sk
  JOIN ship_mode sm                ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
  JOIN warehouse ws                ON cs.cs_warehouse_sk    = ws.w_warehouse_sk
  JOIN item i                      ON cs.cs_item_sk         = i.i_item_sk
  JOIN agg_store_sales agg         ON agg.ss_item_sk        = i.i_item_sk
  WHERE cd.cd_purchase_estimate       > 6000
    AND ib.ib_lower_bound            >= 30000
    AND ca.ca_state                  = 'CA'
    AND sm.sm_type                   = 'AIR'
    AND i.i_current_price            > 100
    AND i.i_item_sk IN (SELECT cs_item_sk FROM high_interest_items)
  GROUP BY i.i_item_id, i.i_item_desc, cp.cp_department, ws.w_warehouse_name

  UNION DISTINCT

  -- Second branch: web returns + store returns side‑by‑side
  SELECT
    i.i_item_id                                    AS item_id,
    i.i_item_desc                                 AS item_desc,
    wp.wp_type                                    AS department,
    CAST(NULL AS varchar)                         AS warehouse_name,
    SUM(wr.wr_return_amt)                         AS total_sales,
    SUM(sr.sr_return_amt)                         AS total_store_activity,
    ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY SUM(wr.wr_return_amt) DESC) AS department_rank,
    'WEB'                                         AS source,
    (SELECT AVG(cd2.cd_purchase_estimate) FROM customer_demographics cd2) AS avg_demo_purchase_estimate
  FROM store_returns sr
  JOIN store_sales ss          ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk       = ss.ss_item_sk
  JOIN item i                  ON ss.ss_item_sk        = i.i_item_sk
  JOIN web_returns wr          ON wr.wr_item_sk       = i.i_item_sk
  JOIN web_page wp             ON wr.wr_web_page_sk   = wp.wp_web_page_sk
  WHERE i.i_current_price    > 100
    AND wr.wr_return_amt    > 50
    AND sr.sr_return_amt    > 50
    AND wp.wp_type           IN ('CONTENT', 'NAVIGATION')
    AND i.i_item_sk IN (SELECT cs_item_sk FROM high_interest_items)
  GROUP BY i.i_item_id, i.i_item_desc, wp.wp_type
) AS final
ORDER BY final.department_rank, final.total_sales DESC
LIMIT 100
