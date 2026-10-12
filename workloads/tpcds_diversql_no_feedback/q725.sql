WITH
  base_store AS (
    SELECT
      s.s_store_id AS store_id,
      i.i_category AS category,
      SUM(sr.sr_return_amt) AS total_return_amt,
      SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_category_id = 5
      AND sr.sr_return_amt > 0
    GROUP BY s.s_store_id, i.i_category
    HAVING SUM(sr.sr_return_amt) > 1000
  ),
  expanded_store AS (
    SELECT
      store_id,
      category,
      metric,
      value
    FROM base_store
    CROSS JOIN UNNEST(
      MAP(
        ARRAY['return_amt', 'return_qty'],
        ARRAY[total_return_amt, total_return_qty]
      )
    ) AS t(metric, value)
  ),
  base_demo AS (
    SELECT
      cd.cd_credit_rating AS credit_rating,
      i.i_brand AS brand,
      SUM(sr.sr_return_amt) AS total_return_amt,
      SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND i.i_manufact = 'barcallyese'
    GROUP BY cd.cd_credit_rating, i.i_brand
    HAVING SUM(sr.sr_return_quantity) >= 10
  ),
  expanded_demo AS (
    SELECT
      credit_rating,
      brand,
      metric,
      value
    FROM base_demo
    CROSS JOIN UNNEST(
      MAP(
        ARRAY['return_amt', 'return_qty'],
        ARRAY[total_return_amt, total_return_qty]
      )
    ) AS t(metric, value)
  )
SELECT *
FROM expanded_store
UNION ALL
SELECT *
FROM expanded_demo
ORDER BY value DESC
LIMIT 100
