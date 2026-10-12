WITH
  agg_inventory AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (5)
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  item_excl AS (
    SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0
    EXCEPT
    SELECT wr_item_sk FROM web_returns WHERE wr_return_quantity > 0
  ),
  cust_filter AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_birth_year BETWEEN 1950 AND 1965
      AND c_salutation = 'Mr.'
  )
SELECT
  d.d_year,
  i.i_category,
  p.p_promo_name,
  SUM(unified.sales_amount)   AS total_sales,
  SUM(unified.return_amount)  AS total_returns,
  SUM(unified.inventory_qty)  AS total_inventory,
  COUNT(DISTINCT unified.customer_sk) AS unique_customers
FROM (
  -- Store‑sales branch
  SELECT
    ss.ss_sold_date_sk            AS date_sk,
    ss.ss_item_sk                 AS item_sk,
    ss.ss_promo_sk                AS promo_sk,
    ss.ss_customer_sk             AS customer_sk,
    ss.ss_ext_sales_price         AS sales_amount,
    0.0                           AS return_amount,
    COALESCE(ai.total_qty, 0)     AS inventory_qty
  FROM store_sales ss
  JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN agg_inventory ai     ON i.i_item_sk = ai.inv_item_sk
  LEFT JOIN warehouse w          ON ai.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND ca.ca_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ss.ss_quantity > 0
    AND ss.ss_customer_sk IN (SELECT c_customer_sk FROM cust_filter)
    AND i.i_item_sk IN (SELECT cr_item_sk FROM item_excl)

  UNION DISTINCT

  -- Catalog‑returns / web‑sales branch (fact RIGHT‑OUTER‑JOINed to dimension)
  SELECT
    cr.cr_returned_date_sk        AS date_sk,
    cr.cr_item_sk                 AS item_sk,
    NULL                          AS promo_sk,
    cr.cr_refunded_customer_sk    AS customer_sk,
    COALESCE(ws.ws_ext_sales_price, 0)                AS sales_amount,
    cr.cr_return_amount + COALESCE(wr.wr_return_amt, 0) AS return_amount,
    COALESCE(ai.total_qty, 0)                         AS inventory_qty
  FROM catalog_returns cr
  RIGHT OUTER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i                    ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN customer c           ON cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN customer_address ca  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN web_sales ws         ON cr.cr_order_number = ws.ws_order_number
  LEFT JOIN web_returns wr       ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN agg_inventory ai     ON i.i_item_sk = ai.inv_item_sk
  WHERE d.d_year = 2001
    AND cp.cp_type = 'A'
    AND r.r_reason_desc = 'Customer not interested'
    AND cr.cr_return_quantity > 0
    AND cr.cr_refunded_customer_sk IN (SELECT c_customer_sk FROM cust_filter)
    AND cr.cr_item_sk IN (SELECT cr_item_sk FROM item_excl)
) AS unified
JOIN date_dim d   ON unified.date_sk = d.d_date_sk
JOIN item i       ON unified.item_sk = i.i_item_sk
LEFT JOIN promotion p ON unified.promo_sk = p.p_promo_sk
GROUP BY ROLLUP (d.d_year, i.i_category, p.p_promo_name)
HAVING SUM(unified.sales_amount) + SUM(unified.return_amount) > 0
ORDER BY d.d_year, i.i_category
LIMIT 100
