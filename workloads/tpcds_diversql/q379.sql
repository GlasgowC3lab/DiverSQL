WITH
  sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (5) -- sample 5% of rows
  ),
  joined AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_hdemo_sk,
      ss.ss_promo_sk,
      ss.ss_customer_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      hd.hd_income_band_sk,
      p.p_discount_active,
      p.p_channel_radio,
      p.p_channel_event
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001                    -- filter 1
      AND d.d_month_seq BETWEEN 1200 AND 1215  -- filter 2
      AND i.i_current_price > 10               -- filter 3
      AND hd.hd_income_band_sk IN (1,2,3)      -- filter 4
      AND p.p_discount_active = 'Y'           -- filter 5
      AND p.p_channel_radio = 'N'              -- extra filter
      AND p.p_channel_event = 'N'              -- extra filter
  ),
  promo_items AS (
    SELECT DISTINCT p.p_item_sk AS item_sk
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_year = 2001
  ),
  sales_items AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_ext_sales_price > 5000
  ),
  common_items AS (
    SELECT item_sk FROM promo_items
    INTERSECT
    SELECT item_sk FROM sales_items
  ),
  final_sales AS (
    SELECT *
    FROM joined
    WHERE ss_ticket_number NOT IN (
        SELECT ss_ticket_number FROM store_sales WHERE ss_coupon_amt > 3000
      )
      AND ss_item_sk IN (SELECT item_sk FROM common_items)
  ),
  agg2 AS (
    SELECT
      d_year,
      d_month_seq,
      i_category,
      SUM(ss_ext_sales_price) AS month_category_sales,
      COUNT(DISTINCT ss_customer_sk) AS month_distinct_customers,
      COUNT(DISTINCT i_brand) AS distinct_brands
    FROM final_sales
    GROUP BY d_year, d_month_seq, i_category
  )
SELECT *
FROM agg2
ORDER BY month_category_sales DESC
OFFSET 10 LIMIT 100
