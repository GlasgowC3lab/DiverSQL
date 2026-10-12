WITH sales_agg AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    i.i_category,
    d_sold.d_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_volume_flag
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d_sold.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 50
    AND cd.cd_gender = 'M'
    AND cs.cs_quantity > 1
    AND cs.cs_wholesale_cost < 5000
    AND cs.cs_net_paid > 0
    AND cs.cs_list_price BETWEEN 20 AND 500
  GROUP BY cs.cs_order_number, cs.cs_item_sk, i.i_category, d_sold.d_year
),

returns_agg AS (
  SELECT
    cr.cr_order_number,
    cr.cr_item_sk,
    i.i_category,
    d_ret.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'BIG' ELSE 'SMALL' END AS return_size_flag
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE d_ret.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 50
    AND cd.cd_gender = 'M'
    AND cr.cr_return_quantity > 0
    AND cr.cr_return_amount > 0
    AND cr.cr_fee < 100
    AND cr.cr_store_credit < 5000
    AND cr.cr_net_loss <> 0
  GROUP BY cr.cr_order_number, cr.cr_item_sk, i.i_category, d_ret.d_year
),

store_agg AS (
  SELECT
    s.s_store_id,
    d_closed.d_year,
    SUM(s.s_number_employees) AS total_employees,
    COUNT(*) AS store_cnt,
    CASE WHEN AVG(s.s_gmt_offset) > 0 THEN 'EAST' ELSE 'WEST' END AS region_flag
  FROM store s
  JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
  WHERE s.s_country = 'United States'
    AND s.s_number_employees BETWEEN 200 AND 300
    AND s.s_tax_percentage < 0.08
    AND d_closed.d_year BETWEEN 2000 AND 2002
    AND s.s_gmt_offset IS NOT NULL
    AND s.s_market_id IN (1, 2, 3)
  GROUP BY s.s_store_id, d_closed.d_year
),

web_returns_agg AS (
  SELECT
    wr.wr_order_number,
    wr.wr_item_sk,
    i.i_category,
    d_wr.d_year,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    COUNT(*) AS web_return_cnt,
    CASE WHEN SUM(wr.wr_return_amt) > 3000 THEN 'BIG_WEB' ELSE 'SMALL_WEB' END AS web_return_flag
  FROM web_returns wr
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE d_wr.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 50
    AND cd.cd_gender = 'M'
    AND wr.wr_return_quantity > 0
    AND wr.wr_return_amt > 0
    AND wr.wr_fee < 50
    AND wr.wr_account_credit < 1000
  GROUP BY wr.wr_order_number, wr.wr_item_sk, i.i_category, d_wr.d_year
),

order_intersection AS (
  SELECT cs_order_number AS order_number FROM sales_agg
  INTERSECT
  SELECT cr_order_number FROM returns_agg
),

final_agg AS (
  SELECT
    sa.d_year,
    sa.i_category,
    SUM(sa.total_net_paid) AS year_category_sales,
    SUM(ra.total_return_amount) AS year_category_returns,
    COUNT(DISTINCT sa.cs_order_number) AS num_sales_orders,
    COUNT(DISTINCT ra.cr_order_number) AS num_return_orders,
    CASE
      WHEN SUM(ra.total_return_amount) = 0 THEN 0
      ELSE SUM(sa.total_net_paid) / SUM(ra.total_return_amount)
    END AS sales_to_return_ratio
  FROM sales_agg sa
  LEFT JOIN returns_agg ra
    ON sa.cs_order_number = ra.cr_order_number
   AND sa.cs_item_sk = ra.cr_item_sk
   AND sa.d_year = ra.d_year
  WHERE sa.cs_order_number IN (SELECT order_number FROM order_intersection)
  GROUP BY sa.d_year, sa.i_category
)

SELECT
  f.d_year,
  f.i_category,
  f.year_category_sales,
  f.year_category_returns,
  f.num_sales_orders,
  f.num_return_orders,
  f.sales_to_return_ratio,
  CASE WHEN f.sales_to_return_ratio > 1 THEN 'PROFITABLE' ELSE 'UNPROFITABLE' END AS profitability_flag
FROM final_agg f
ORDER BY f.year_category_sales DESC
LIMIT 100
