WITH
  /* 1. Expand words from catalog page description */
  catalog_page_words AS (
    SELECT cp.cp_catalog_page_sk,
           word
    FROM catalog_page cp
    CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(word)
    WHERE lower(word) = 'girls'
  ),

  /* 2. Aggregate store return information */
  store_ret_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      d.d_year,
      d.d_month_seq,
      SUM(sr.sr_net_loss)               AS store_net_loss,
      COUNT(*)                           AS store_return_cnt,
      SUM(sr.sr_return_quantity)        AS total_qty,
      ROW_NUMBER() OVER (
        PARTITION BY s.s_store_sk
        ORDER BY d.d_year, d.d_month_seq
      )                                 AS store_rn
    FROM store_returns AS sr
    JOIN date_dim AS d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim AS t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store AS s
      ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2000                                 -- predicate 1
      AND s.s_tax_percentage > 5.0                        -- predicate 2
      AND s.s_state = 'CA'                                -- predicate 3
      AND sr.sr_return_ship_cost > 0                      -- predicate 4
      AND sr.sr_return_amt_inc_tax > 0                    -- predicate 5
      AND sr.sr_return_quantity > 0                      -- predicate 6
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
  ),

  /* 3. Aggregate catalog return information (only pages that contain the word ‘girls’) */
  catalog_ret_agg AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_type,
      d.d_year,
      d.d_month_seq,
      SUM(cr.cr_net_loss)               AS catalog_net_loss,
      COUNT(*)                           AS catalog_return_cnt,
      SUM(cr.cr_return_quantity)        AS catalog_qty,
      ROW_NUMBER() OVER (
        PARTITION BY cp.cp_catalog_page_sk
        ORDER BY d.d_year, d.d_month_seq
      )                                 AS catalog_rn
    FROM catalog_returns AS cr
    JOIN date_dim AS d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim AS t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page AS cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_page_words AS cpw
      ON cp.cp_catalog_page_sk = cpw.cp_catalog_page_sk
    WHERE d.d_year = 2000                                 -- predicate 7
      AND cp.cp_type = 'A'                               -- predicate 8
      AND cr.cr_return_amount > 0                        -- predicate 9
      AND cr.cr_return_quantity > 0                      -- predicate 10
      AND cr.cr_fee >= 0                                 -- predicate 11
      AND cp.cp_catalog_number BETWEEN 1 AND 1000       -- predicate 12
    GROUP BY cp.cp_catalog_page_sk, cp.cp_type, d.d_year, d.d_month_seq
  ),

  /* 4. Aggregate inventory information */
  inventory_agg AS (
    SELECT
      i.inv_item_sk,
      d.d_year,
      d.d_month_seq,
      SUM(i.inv_quantity_on_hand) AS total_on_hand,
      MAX(i.inv_quantity_on_hand) AS max_on_hand
    FROM inventory AS i
    JOIN date_dim AS d
      ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2000                                 -- predicate 13
      AND i.inv_quantity_on_hand > 0                     -- predicate 14
    GROUP BY i.inv_item_sk, d.d_year, d.d_month_seq
  ),

  /* 5. Aggregate web‑page activity */
  web_page_agg AS (
    SELECT
      wp.wp_web_page_sk,
      d_cre.d_year    AS creation_year,
      d_cre.d_month_seq AS creation_month,
      d_acc.d_year    AS access_year,
      d_acc.d_month_seq AS access_month,
      COUNT(*)        AS page_visits
    FROM web_page AS wp
    JOIN date_dim AS d_cre
      ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim AS d_acc
      ON wp.wp_access_date_sk = d_acc.d_date_sk
    WHERE wp.wp_type = 'HTML'                             -- predicate 15
      AND d_cre.d_year = 2000                             -- predicate 16
      AND d_acc.d_year = 2000                             -- predicate 17
    GROUP BY wp.wp_web_page_sk, d_cre.d_year, d_cre.d_month_seq,
             d_acc.d_year, d_acc.d_month_seq
  ),

  /* 6. Union of store and catalog return aggregates */
  combined_returns AS (
    SELECT
      'store'   AS entity_type,
      CAST(sra.s_store_sk AS BIGINT) AS entity_id,
      sra.d_year,
      sra.d_month_seq,
      sra.store_net_loss AS net_loss,
      sra.store_return_cnt AS return_cnt
    FROM store_ret_agg sra
    UNION DISTINCT
    SELECT
      'catalog' AS entity_type,
      CAST(cra.cp_catalog_page_sk AS BIGINT) AS entity_id,
      cra.d_year,
      cra.d_month_seq,
      cra.catalog_net_loss AS net_loss,
      cra.catalog_return_cnt AS return_cnt
    FROM catalog_ret_agg cra
  ),

  /* 7. Apply additional filtering and subtract rows with zero loss */
  filtered_combined AS (
    SELECT cr.*
    FROM combined_returns cr
    WHERE cr.net_loss > 0                                 -- predicate 18
      AND cr.return_cnt > 1                               -- predicate 19
      AND EXISTS (                                         -- subquery predicate
        SELECT 1
        FROM inventory_agg ia
        WHERE ia.inv_item_sk = cr.entity_id
      )
      AND cr.entity_type = 'catalog'                      -- predicate 20
      AND cr.d_month_seq BETWEEN 1 AND 12                -- predicate 21
    EXCEPT
    SELECT cr2.*
    FROM combined_returns cr2
    WHERE cr2.net_loss = 0
  ),

  /* 8. Final aggregation with ranking and a scalar subquery */
  final_agg AS (
    SELECT
      fc.entity_type,
      fc.d_year,
      fc.d_month_seq,
      AVG(fc.net_loss)           AS avg_net_loss,
      SUM(fc.return_cnt)         AS total_returns,
      ROW_NUMBER() OVER (PARTITION BY fc.entity_type ORDER BY AVG(fc.net_loss) DESC) AS rank_within_type,
      ROW_NUMBER() OVER (ORDER BY AVG(fc.net_loss) DESC)                        AS global_row_num,
      (SELECT MAX(total_on_hand) FROM inventory_agg)                           AS max_inventory_global
    FROM filtered_combined fc
    GROUP BY fc.entity_type, fc.d_year, fc.d_month_seq
    HAVING SUM(fc.return_cnt) > 5                         -- predicate 22
  )
SELECT
  entity_type,
  d_year,
  d_month_seq,
  avg_net_loss,
  total_returns,
  rank_within_type,
  global_row_num,
  max_inventory_global
FROM final_agg
ORDER BY entity_type, avg_net_loss DESC
LIMIT 100
