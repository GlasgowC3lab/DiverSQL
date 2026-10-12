WITH
dim_date AS (
   SELECT d_date_sk,
          d_year,
          d_quarter_name
   FROM date_dim
),
dim_item AS (
   SELECT i_item_sk,
          i_category,
          i_brand
   FROM item
),

catalog_sales_agg AS (
   SELECT
     cd.d_year,
     cd.d_quarter_name,
     di.i_category,
     di.i_brand,
     sum(cs.cs_net_paid) AS total_net_paid,
     sum(cs.cs_net_profit) AS total_net_profit,
     sum(cs.cs_ext_discount_amt) AS total_discount_amount,
     sum(cs.cs_quantity) AS total_quantity,
     count(distinct cs.cs_order_number) AS order_cnt,
     count(distinct cs.cs_bill_customer_sk) AS distinct_customer_cnt,
     avg(cs.cs_ext_discount_amt / nullif(cs.cs_quantity,0)) AS avg_discount_per_item,
     coalesce(sum(p.p_cost),0) AS total_promo_cost,
     count(distinct p.p_promo_id) AS promo_cnt
   FROM catalog_sales cs
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN dim_date cd ON cs.cs_sold_date_sk = cd.d_date_sk
   JOIN dim_item di ON cs.cs_item_sk = di.i_item_sk
   GROUP BY cd.d_year, cd.d_quarter_name, di.i_category, di.i_brand
),

catalog_returns_agg AS (
   SELECT
     cd.d_year,
     cd.d_quarter_name,
     di.i_category,
     di.i_brand,
     sum(cr.cr_net_loss) AS total_return_loss,
     sum(cr.cr_return_quantity) AS total_return_quantity
   FROM catalog_returns cr
   JOIN dim_date cd ON cr.cr_returned_date_sk = cd.d_date_sk
   JOIN dim_item di ON cr.cr_item_sk = di.i_item_sk
   GROUP BY cd.d_year, cd.d_quarter_name, di.i_category, di.i_brand
),

store_sales_agg AS (
   SELECT
     cd.d_year,
     cd.d_quarter_name,
     di.i_category,
     di.i_brand,
     sum(ss.ss_net_paid) AS total_net_paid,
     sum(ss.ss_net_profit) AS total_net_profit,
     sum(ss.ss_ext_discount_amt) AS total_discount_amount,
     sum(ss.ss_quantity) AS total_quantity,
     count(distinct ss.ss_ticket_number) AS order_cnt,
     count(distinct ss.ss_customer_sk) AS distinct_customer_cnt,
     avg(ss.ss_ext_discount_amt / nullif(ss.ss_quantity,0)) AS avg_discount_per_item,
     coalesce(sum(p.p_cost),0) AS total_promo_cost,
     count(distinct p.p_promo_id) AS promo_cnt
   FROM store_sales ss
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN dim_date cd ON ss.ss_sold_date_sk = cd.d_date_sk
   JOIN dim_item di ON ss.ss_item_sk = di.i_item_sk
   GROUP BY cd.d_year, cd.d_quarter_name, di.i_category, di.i_brand
),

store_returns_agg AS (
   SELECT
     cd.d_year,
     cd.d_quarter_name,
     di.i_category,
     di.i_brand,
     sum(sr.sr_net_loss) AS total_return_loss,
     sum(sr.sr_return_quantity) AS total_return_quantity
   FROM store_returns sr
   JOIN dim_date cd ON sr.sr_returned_date_sk = cd.d_date_sk
   JOIN dim_item di ON sr.sr_item_sk = di.i_item_sk
   GROUP BY cd.d_year, cd.d_quarter_name, di.i_category, di.i_brand
),

web_sales_agg AS (
   SELECT
     cd.d_year,
     cd.d_quarter_name,
     di.i_category,
     di.i_brand,
     sum(ws.ws_net_paid) AS total_net_paid,
     sum(ws.ws_net_profit) AS total_net_profit,
     sum(ws.ws_ext_discount_amt) AS total_discount_amount,
     sum(ws.ws_quantity) AS total_quantity,
     count(distinct ws.ws_order_number) AS order_cnt,
     count(distinct ws.ws_bill_customer_sk) AS distinct_customer_cnt,
     avg(ws.ws_ext_discount_amt / nullif(ws.ws_quantity,0)) AS avg_discount_per_item,
     coalesce(sum(p.p_cost),0) AS total_promo_cost,
     count(distinct p.p_promo_id) AS promo_cnt
   FROM web_sales ws
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN dim_date cd ON ws.ws_sold_date_sk = cd.d_date_sk
   JOIN dim_item di ON ws.ws_item_sk = di.i_item_sk
   GROUP BY cd.d_year, cd.d_quarter_name, di.i_category, di.i_brand
),

web_returns_agg AS (
   SELECT
     cd.d_year,
     cd.d_quarter_name,
     di.i_category,
     di.i_brand,
     sum(wr.wr_net_loss) AS total_return_loss,
     sum(wr.wr_return_quantity) AS total_return_quantity
   FROM web_returns wr
   JOIN dim_date cd ON wr.wr_returned_date_sk = cd.d_date_sk
   JOIN dim_item di ON wr.wr_item_sk = di.i_item_sk
   GROUP BY cd.d_year, cd.d_quarter_name, di.i_category, di.i_brand
),

catalog_combined AS (
   SELECT
     'catalog' AS channel,
     ca.d_year,
     ca.d_quarter_name,
     ca.i_category,
     ca.i_brand,
     ca.total_net_paid,
     ca.total_net_profit,
     ca.total_discount_amount,
     ca.total_quantity,
     ca.order_cnt,
     ca.distinct_customer_cnt,
     ca.avg_discount_per_item,
     ca.total_promo_cost,
     ca.promo_cnt,
     coalesce(cr.total_return_loss, 0) AS total_return_loss,
     coalesce(cr.total_return_quantity, 0) AS total_return_quantity,
     ca.total_net_profit - coalesce(cr.total_return_loss, 0) AS net_profit_after_returns
   FROM catalog_sales_agg ca
   LEFT JOIN catalog_returns_agg cr
     ON ca.d_year = cr.d_year
    AND ca.d_quarter_name = cr.d_quarter_name
    AND ca.i_category = cr.i_category
    AND ca.i_brand = cr.i_brand
),

store_combined AS (
   SELECT
     'store' AS channel,
     sa.d_year,
     sa.d_quarter_name,
     sa.i_category,
     sa.i_brand,
     sa.total_net_paid,
     sa.total_net_profit,
     sa.total_discount_amount,
     sa.total_quantity,
     sa.order_cnt,
     sa.distinct_customer_cnt,
     sa.avg_discount_per_item,
     sa.total_promo_cost,
     sa.promo_cnt,
     coalesce(sr.total_return_loss, 0) AS total_return_loss,
     coalesce(sr.total_return_quantity, 0) AS total_return_quantity,
     sa.total_net_profit - coalesce(sr.total_return_loss, 0) AS net_profit_after_returns
   FROM store_sales_agg sa
   LEFT JOIN store_returns_agg sr
     ON sa.d_year = sr.d_year
    AND sa.d_quarter_name = sr.d_quarter_name
    AND sa.i_category = sr.i_category
    AND sa.i_brand = sr.i_brand
),

web_combined AS (
   SELECT
     'web' AS channel,
     wa.d_year,
     wa.d_quarter_name,
     wa.i_category,
     wa.i_brand,
     wa.total_net_paid,
     wa.total_net_profit,
     wa.total_discount_amount,
     wa.total_quantity,
     wa.order_cnt,
     wa.distinct_customer_cnt,
     wa.avg_discount_per_item,
     wa.total_promo_cost,
     wa.promo_cnt,
     coalesce(wr.total_return_loss, 0) AS total_return_loss,
     coalesce(wr.total_return_quantity, 0) AS total_return_quantity,
     wa.total_net_profit - coalesce(wr.total_return_loss, 0) AS net_profit_after_returns
   FROM web_sales_agg wa
   LEFT JOIN web_returns_agg wr
     ON wa.d_year = wr.d_year
    AND wa.d_quarter_name = wr.d_quarter_name
    AND wa.i_category = wr.i_category
    AND wa.i_brand = wr.i_brand
),

all_channels AS (
   SELECT * FROM catalog_combined
   UNION ALL
   SELECT * FROM store_combined
   UNION ALL
   SELECT * FROM web_combined
),

ranked AS (
   SELECT
     channel,
     d_year,
     d_quarter_name,
     i_category,
     i_brand,
     total_net_paid,
     total_net_profit,
     total_discount_amount,
     total_quantity,
     order_cnt,
     distinct_customer_cnt,
     avg_discount_per_item,
     total_promo_cost,
     promo_cnt,
     total_return_loss,
     total_return_quantity,
     net_profit_after_returns,
     row_number() OVER (PARTITION BY channel, d_year, d_quarter_name ORDER BY net_profit_after_returns DESC) AS rn
   FROM all_channels
)

SELECT
   channel,
   d_year,
   d_quarter_name,
   i_category,
   i_brand,
   total_net_paid,
   total_net_profit,
   total_discount_amount,
   total_quantity,
   order_cnt,
   distinct_customer_cnt,
   avg_discount_per_item,
   total_promo_cost,
   promo_cnt,
   total_return_loss,
   total_return_quantity,
   net_profit_after_returns
FROM ranked
WHERE rn <= 10
ORDER BY channel, d_year, d_quarter_name, net_profit_after_returns DESC
