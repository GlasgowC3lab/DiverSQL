WITH sales_agg AS (
   SELECT
       d_sold.d_year,
       i.i_category,
       i.i_brand,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(cs.cs_ext_discount_amt) AS total_discount,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
   GROUP BY d_sold.d_year, i.i_category, i.i_brand
),
returns_agg AS (
   SELECT
       d_ret.d_year AS return_year,
       i.i_category,
       SUM(sr.sr_return_amt) AS total_returns,
       COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
   JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
   GROUP BY d_ret.d_year, i.i_category
)
SELECT
   sa.d_year,
   sa.i_category,
   sa.i_brand,
   sa.total_sales,
   ra.total_returns,
   sa.order_cnt,
   ra.return_cnt,
   ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS global_sales_rank,
   DENSE_RANK() OVER (PARTITION BY sa.i_category ORDER BY sa.total_sales DESC) AS category_sales_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
   ON sa.d_year = ra.return_year
  AND sa.i_category = ra.i_category
ORDER BY global_sales_rank
LIMIT 100
