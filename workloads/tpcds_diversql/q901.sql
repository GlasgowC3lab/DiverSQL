WITH high_price_items AS (
  SELECT i_item_sk FROM item WHERE i_current_price > 100
),
low_price_items AS (
  SELECT i_item_sk FROM item WHERE i_current_price < 20
),
price_diff_items AS (
  SELECT i_item_sk FROM high_price_items
  EXCEPT
  SELECT i_item_sk FROM low_price_items
),
base AS (
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_fee,
    d.d_year,
    i.i_product_name,
    i.i_current_price,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    ca.ca_city,
    ca.ca_state
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_item_sk IN (SELECT i_item_sk FROM price_diff_items)
    AND regexp_like(i.i_product_name, '[0-9]{3}')
    AND ca.ca_city LIKE '%York%'
)
SELECT
  regexp_extract(b.i_product_name, '([0-9]{3})', 1) AS product_code,
  concat(b.ca_city, ', ', b.ca_state) AS city_state,
  b.ib_upper_bound,
  b.hd_buy_potential,
  b.d_year,
  SUM(b.wr_return_amt) AS total_return_amt,
  SUM(b.wr_fee) AS total_fee,
  COUNT(*) AS returns_cnt,
  (SELECT AVG(wr_fee) FROM web_returns) AS avg_fee_overall,
  ROW_NUMBER() OVER (ORDER BY SUM(b.wr_return_amt) DESC) AS rn,
  lt.year_item_return_cnt
FROM base b
CROSS JOIN LATERAL (
  SELECT COUNT(*) AS year_item_return_cnt
  FROM web_returns wr2
  WHERE wr2.wr_item_sk = b.wr_item_sk
    AND wr2.wr_returned_date_sk = b.wr_returned_date_sk
) AS lt
GROUP BY
  regexp_extract(b.i_product_name, '([0-9]{3})', 1),
  concat(b.ca_city, ', ', b.ca_state),
  b.ib_upper_bound,
  b.hd_buy_potential,
  b.d_year,
  lt.year_item_return_cnt
ORDER BY total_return_amt DESC
LIMIT 100
