WITH
  sales_agg AS (
    SELECT
      ss_item_sk,
      ss_addr_sk,
      SUM(ss_quantity) AS total_qty,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_ext_tax > 10
      AND ss_ext_sales_price IS NOT NULL
      AND ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ss_item_sk, ss_addr_sk
  ),

  returns_agg AS (
    SELECT
      cr_item_sk,
      cr_refunded_addr_sk,
      COUNT(*) AS return_cnt,
      SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cr_item_sk, cr_refunded_addr_sk
  ),

  rank_limits AS (
    SELECT 1 AS k UNION ALL SELECT 2 AS k
  ),

  category_dim AS (
    SELECT DISTINCT i_category, i_category_id
    FROM item
    WHERE i_category_id IN (6, 8, 9)
  ),

  joined AS (
    SELECT
      cat.i_category,
      ca_sales.ca_state,
      i.i_item_id,
      i.i_brand,
      sa.total_sales,
      ra.total_return_amount,
      inv.inv_quantity_on_hand,
      rl.k,
      ROW_NUMBER() OVER (PARTITION BY cat.i_category, ca_sales.ca_state ORDER BY sa.total_sales DESC) AS rn
    FROM category_dim cat
    CROSS JOIN rank_limits rl
    JOIN item i
      ON i.i_category = cat.i_category
    JOIN sales_agg sa
      ON sa.ss_item_sk = i.i_item_sk
    JOIN customer_address ca_sales
      ON ca_sales.ca_address_sk = sa.ss_addr_sk
    LEFT JOIN returns_agg ra
      ON ra.cr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv_check
        WHERE inv_check.inv_item_sk = i.i_item_sk
          AND inv_check.inv_quantity_on_hand > 100
      )
      AND i.i_rec_start_date > DATE '2000-01-01'
      AND i.i_manufact_id IN (214, 479)
  )
SELECT
  i_category,
  ca_state,
  i_item_id,
  i_brand,
  total_sales,
  total_return_amount,
  inv_quantity_on_hand,
  rn,
  k
FROM joined
WHERE rn <= k
ORDER BY i_category, ca_state, rn
LIMIT 100
