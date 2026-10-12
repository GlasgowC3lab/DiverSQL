WITH
  ss_agg AS (
    SELECT
      ss_item_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_quantity) AS total_qty,
      SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
  ),
  cr_agg AS (
    SELECT
      cr_item_sk,
      cr_returned_date_sk,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_item_sk, cr_returned_date_sk
  ),
  wr_agg AS (
    SELECT
      wr_item_sk,
      wr_returned_date_sk,
      SUM(wr_return_amt) AS total_web_return_amt,
      SUM(wr_return_quantity) AS total_web_return_qty
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_item_sk, wr_returned_date_sk
  ),
  key_set_a AS (
    SELECT ss_item_sk AS item_key FROM store_sales WHERE ss_quantity > 5
  ),
  key_set_b AS (
    SELECT cr_item_sk AS item_key FROM catalog_returns WHERE cr_return_quantity > 2
  )
SELECT
  i.i_item_sk,
  i.i_item_id,
  d.d_date,
  i.i_brand,
  i.i_category,
  ss_agg.total_sales,
  ss_agg.total_profit,
  cr_agg.total_return_amount,
  wr_agg.total_web_return_amt,
  ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY ss_agg.total_sales DESC) AS brand_sales_rank,
  CASE
    WHEN cr_agg.total_return_amount > 1000 THEN 'HIGH_RETURN'
    ELSE 'NORMAL_RETURN'
  END AS return_category
FROM ss_agg
JOIN store_sales ss
  ON ss.ss_item_sk = ss_agg.ss_item_sk
 AND ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
 AND p.p_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN cr_agg
  ON cr_agg.cr_item_sk = i.i_item_sk
 AND cr_agg.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN wr_agg
  ON wr_agg.wr_item_sk = i.i_item_sk
 AND wr_agg.wr_returned_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND i.i_current_price BETWEEN 10 AND 100
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND ca.ca_country = 'United States'
  AND i.i_item_sk NOT IN (
    SELECT item_key FROM key_set_a
    INTERSECT
    SELECT item_key FROM key_set_b
  )
GROUP BY
  i.i_item_sk,
  i.i_item_id,
  d.d_date,
  i.i_brand,
  i.i_category,
  ss_agg.total_sales,
  ss_agg.total_profit,
  cr_agg.total_return_amount,
  wr_agg.total_web_return_amt,
  i.i_brand
HAVING
  SUM(ss_agg.total_sales) > 5000
ORDER BY
  ss_agg.total_sales DESC
LIMIT 100
