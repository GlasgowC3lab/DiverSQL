WITH
sales_agg AS (
 SELECT
   cs_sold_date_sk AS date_sk,
   cs_item_sk AS item_sk,
   SUM(cs_net_paid) AS net_paid,
   SUM(cs_net_profit) AS net_profit,
   SUM(cs_coupon_amt) AS coupon_amt,
   SUM(cs_ext_sales_price) AS ext_sales_price,
   SUM(cs_quantity) AS quantity
 FROM catalog_sales
 GROUP BY cs_sold_date_sk, cs_item_sk
 UNION ALL
 SELECT
   ws_sold_date_sk,
   ws_item_sk,
   SUM(ws_net_paid),
   SUM(ws_net_profit),
   SUM(ws_coupon_amt),
   SUM(ws_ext_sales_price),
   SUM(ws_quantity)
 FROM web_sales
 GROUP BY ws_sold_date_sk, ws_item_sk
 UNION ALL
 SELECT
   ss_sold_date_sk,
   ss_item_sk,
   SUM(ss_net_paid),
   SUM(ss_net_profit),
   SUM(ss_coupon_amt),
   SUM(ss_ext_sales_price),
   SUM(ss_quantity)
 FROM store_sales
 GROUP BY ss_sold_date_sk, ss_item_sk
),
sales_by_date_item AS (
 SELECT
   date_sk,
   item_sk,
   SUM(net_paid) AS net_paid,
   SUM(net_profit) AS net_profit,
   SUM(coupon_amt) AS coupon_amt,
   SUM(ext_sales_price) AS ext_sales_price,
   SUM(quantity) AS quantity
 FROM sales_agg
 GROUP BY date_sk, item_sk
),
returns_agg AS (
 SELECT
   cr_returned_date_sk AS date_sk,
   cr_item_sk AS item_sk,
   SUM(cr_net_loss) AS net_loss,
   SUM(cr_return_amt_inc_tax) AS ext_return_amount,
   SUM(cr_return_quantity) AS return_quantity,
   SUM(cr_fee) AS fee
 FROM catalog_returns
 GROUP BY cr_returned_date_sk, cr_item_sk
 UNION ALL
 SELECT
   sr_returned_date_sk,
   sr_item_sk,
   SUM(sr_net_loss),
   SUM(sr_return_amt_inc_tax),
   SUM(sr_return_quantity),
   SUM(sr_fee)
 FROM store_returns
 GROUP BY sr_returned_date_sk, sr_item_sk
 UNION ALL
 SELECT
   wr_returned_date_sk,
   wr_item_sk,
   SUM(wr_net_loss),
   SUM(wr_return_amt_inc_tax),
   SUM(wr_return_quantity),
   SUM(wr_fee)
 FROM web_returns
 GROUP BY wr_returned_date_sk, wr_item_sk
),
returns_by_date_item AS (
 SELECT
   date_sk,
   item_sk,
   SUM(net_loss) AS net_loss,
   SUM(ext_return_amount) AS ext_return_amount,
   SUM(return_quantity) AS return_quantity,
   SUM(fee) AS fee
 FROM returns_agg
 GROUP BY date_sk, item_sk
),
joined AS (
 SELECT
   COALESCE(s.date_sk, r.date_sk) AS date_sk,
   COALESCE(s.item_sk, r.item_sk) AS item_sk,
   s.net_paid,
   s.net_profit,
   s.coupon_amt,
   s.ext_sales_price,
   s.quantity AS sold_quantity,
   r.net_loss,
   r.ext_return_amount,
   r.return_quantity,
   r.fee AS return_fee
 FROM sales_by_date_item s
 FULL OUTER JOIN returns_by_date_item r
   ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk
),
final AS (
 SELECT
   d.d_year,
   i.i_category,
   i.i_product_name,
   SUM(COALESCE(j.net_paid, 0)) AS total_net_paid,
   SUM(COALESCE(j.net_profit, 0)) AS total_net_profit,
   SUM(COALESCE(j.net_loss, 0)) AS total_net_loss,
   SUM(COALESCE(j.net_profit, 0)) - SUM(COALESCE(j.net_loss, 0)) AS adjusted_net_profit,
   SUM(COALESCE(j.coupon_amt, 0)) AS total_coupon_amt,
   SUM(COALESCE(j.ext_sales_price, 0)) AS total_ext_sales_price,
   SUM(COALESCE(j.sold_quantity, 0)) AS total_quantity_sold,
   SUM(COALESCE(j.return_quantity, 0)) AS total_quantity_returned,
   SUM(COALESCE(j.ext_return_amount, 0)) AS total_ext_return_amount,
   SUM(COALESCE(j.return_fee, 0)) AS total_return_fee,
   CASE WHEN SUM(COALESCE(j.ext_sales_price, 0)) > 0
        THEN SUM(COALESCE(j.coupon_amt, 0)) / SUM(COALESCE(j.ext_sales_price, 0))
        ELSE NULL
   END AS avg_coupon_rate
 FROM joined j
 JOIN date_dim d ON j.date_sk = d.d_date_sk
 JOIN item i ON j.item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2002
 GROUP BY d.d_year, i.i_category, i.i_product_name
),
ranked AS (
 SELECT
   f.*,
   ROW_NUMBER() OVER (PARTITION BY f.d_year, f.i_category ORDER BY f.adjusted_net_profit DESC) AS rank_in_category
 FROM final f
)
SELECT
   d_year,
   i_category,
   i_product_name,
   total_net_paid,
   total_net_profit,
   total_net_loss,
   adjusted_net_profit,
   total_coupon_amt,
   avg_coupon_rate,
   total_quantity_sold,
   total_quantity_returned,
   rank_in_category
FROM ranked
WHERE rank_in_category <= 5
ORDER BY d_year, i_category, rank_in_category
