/*
Goal: Identify high‑value transactions from stores and catalog sales, deduplicate them, and keep only those whose transaction identifiers appear in both recent store sales and catalog sales. The query classifies each transaction by profit status, enriches store rows with the top‑selling item per store via a LATERAL subquery, and applies various scalar subqueries for dynamic thresholds.
*/
WITH
  /* Store‑side transactions */
  store_union AS (
    SELECT
      ss.ss_ticket_number                     AS trans_id,
      ss.ss_sold_date_sk                      AS date_sk,
      s.s_store_id                            AS source_id,
      c.c_customer_id                         AS customer_id,
      ss.ss_quantity                          AS quantity,
      ss.ss_net_paid                          AS net_paid,
      CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      top_item.top_item_sk                     AS top_item_sk
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    CROSS JOIN LATERAL (
      SELECT ss2.ss_item_sk AS top_item_sk
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = ss.ss_store_sk
      ORDER BY ss2.ss_net_paid DESC
      LIMIT 1
    ) AS top_item
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > (SELECT AVG(ss_quantity) FROM store_sales)
      AND ss.ss_net_paid > (
        SELECT MAX(s2.s_gmt_offset)
        FROM store s2
        WHERE s2.s_state = 'TX'
      )
  ),

  /* Catalog‑side transactions */
  catalog_union AS (
    SELECT
      cs.cs_order_number                       AS trans_id,
      cs.cs_sold_date_sk                       AS date_sk,
      cp.cp_catalog_page_id                    AS source_id,
      c.c_customer_id                          AS customer_id,
      cs.cs_quantity                           AS quantity,
      cs.cs_net_paid                           AS net_paid,
      CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      NULL                                      AS top_item_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_type = 'Web'
      AND t.t_hour BETWEEN 9 AND 17
      AND cs.cs_quantity > (SELECT AVG(cs_quantity) FROM catalog_sales)
  ),

  /* Transaction identifiers that exist in BOTH source tables */
  intersect_keys AS (
    SELECT ss_ticket_number AS trans_id FROM store_sales
    INTERSECT
    SELECT cs_order_number  AS trans_id FROM catalog_sales
  ),

  /* Union the two source‑side result sets (deduped by UNION) */
  combined AS (
    SELECT * FROM store_union
    UNION
    SELECT * FROM catalog_union
  )

SELECT
  trans_id,
  date_sk,
  source_id,
  customer_id,
  quantity,
  net_paid,
  profit_flag,
  top_item_sk
FROM combined
WHERE trans_id IN (SELECT trans_id FROM intersect_keys)
ORDER BY net_paid DESC
LIMIT 100
