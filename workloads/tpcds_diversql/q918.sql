WITH
  sales_agg AS (
    SELECT
      cs.cs_sold_date_sk,
      d.d_year,
      cp.cp_department,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      p.p_promo_name,
      SUM(cs.cs_net_paid)               AS total_net_paid,
      SUM(cs.cs_ext_sales_price)        AS total_sales_price,
      COUNT(*)                          AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002          -- predicate 1
      AND cp.cp_department = 'Sports'            -- predicate 2
      AND w.w_state = 'CA'                       -- predicate 3
      AND p.p_discount_active = 'Y'              -- predicate 4
    GROUP BY cs.cs_sold_date_sk, d.d_year, cp.cp_department,
             w.w_warehouse_sk, w.w_warehouse_name, p.p_promo_name
  ),

  returns_agg AS (
    SELECT
      cr.cr_returned_date_sk,
      d_ret.d_year,
      cp_ret.cp_department,
      w_ret.w_warehouse_sk,
      w_ret.w_warehouse_name,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*)                 AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
      AND cp_ret.cp_department = 'Sports'
      AND w_ret.w_state = 'CA'
    GROUP BY cr.cr_returned_date_sk, d_ret.d_year, cp_ret.cp_department,
             w_ret.w_warehouse_sk, w_ret.w_warehouse_name
  ),

  inventory_agg AS (
    SELECT
      i.inv_date_sk,
      d_inv.d_year,
      w_inv.w_warehouse_sk,
      w_inv.w_warehouse_name,
      SUM(i.inv_quantity_on_hand) AS total_on_hand
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE d_inv.d_year BETWEEN 2000 AND 2002
      AND w_inv.w_state = 'CA'
    GROUP BY i.inv_date_sk, d_inv.d_year, w_inv.w_warehouse_sk, w_inv.w_warehouse_name
  ),

  -- Full outer join keeps rows that exist only in sales, only in returns or only in inventory
  full_combined AS (
    SELECT *
    FROM sales_agg
    FULL OUTER JOIN returns_agg
      ON sales_agg.cs_sold_date_sk = returns_agg.cr_returned_date_sk
         AND sales_agg.w_warehouse_sk = returns_agg.w_warehouse_sk
    FULL OUTER JOIN inventory_agg
      ON COALESCE(sales_agg.cs_sold_date_sk, returns_agg.cr_returned_date_sk) = inventory_agg.inv_date_sk
         AND COALESCE(sales_agg.w_warehouse_sk, returns_agg.w_warehouse_sk) = inventory_agg.w_warehouse_sk
  ),

  first_set AS (
    SELECT
      COALESCE(s.cs_sold_date_sk, r.cr_returned_date_sk, i.inv_date_sk) AS date_sk,
      COALESCE(s.w_warehouse_name, r.w_warehouse_name, i.w_warehouse_name) AS warehouse_name,
      s.p_promo_name                                                       AS promo_name,
      s.total_net_paid                                                     AS net_sales,
      r.total_return_amount                                                AS net_returns,
      i.total_on_hand                                                      AS on_hand,
      lt.sales_cnt_per_day
    FROM full_combined fc
    LEFT JOIN sales_agg s ON s.cs_sold_date_sk = fc.cs_sold_date_sk
    LEFT JOIN returns_agg r ON r.cr_returned_date_sk = fc.cr_returned_date_sk
    LEFT JOIN inventory_agg i ON i.inv_date_sk = fc.inv_date_sk
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS sales_cnt_per_day
      FROM catalog_sales cs2
      WHERE cs2.cs_warehouse_sk = COALESCE(s.w_warehouse_sk, r.w_warehouse_sk, i.w_warehouse_sk)
        AND cs2.cs_sold_date_sk = COALESCE(s.cs_sold_date_sk, r.cr_returned_date_sk, i.inv_date_sk)
    ) lt
    WHERE s.total_net_paid > 10000                     -- predicate 5
      AND EXISTS (
            SELECT 1
            FROM promotion p_chk
            WHERE p_chk.p_promo_name = s.p_promo_name
              AND p_chk.p_discount_active = 'Y'
          )
  ),

  second_set AS (
    SELECT
      COALESCE(s.cs_sold_date_sk, r.cr_returned_date_sk, i.inv_date_sk) AS date_sk,
      COALESCE(s.w_warehouse_name, r.w_warehouse_name, i.w_warehouse_name) AS warehouse_name,
      s.p_promo_name                                                       AS promo_name,
      s.total_net_paid                                                     AS net_sales,
      r.total_return_amount                                                AS net_returns,
      i.total_on_hand                                                      AS on_hand,
      lt.sales_cnt_per_day
    FROM full_combined fc
    LEFT JOIN sales_agg s ON s.cs_sold_date_sk = fc.cs_sold_date_sk
    LEFT JOIN returns_agg r ON r.cr_returned_date_sk = fc.cr_returned_date_sk
    LEFT JOIN inventory_agg i ON i.inv_date_sk = fc.inv_date_sk
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS sales_cnt_per_day
      FROM catalog_sales cs2
      WHERE cs2.cs_warehouse_sk = COALESCE(s.w_warehouse_sk, r.w_warehouse_sk, i.w_warehouse_sk)
        AND cs2.cs_sold_date_sk = COALESCE(s.cs_sold_date_sk, r.cr_returned_date_sk, i.inv_date_sk)
    ) lt
    WHERE r.total_return_amount > 5000                -- predicate 6
      AND i.total_on_hand < 2000                      -- predicate 7
  )

SELECT *
FROM (
  SELECT * FROM first_set
  UNION
  SELECT * FROM second_set
) combined
ORDER BY net_sales DESC, warehouse_name
OFFSET 0
LIMIT 100
