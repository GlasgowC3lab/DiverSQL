WITH
store_sales_agg AS (
    SELECT ss_customer_sk AS customer_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_ext_sales_price) AS store_sales,
           SUM(ss_quantity) AS store_qty,
           SUM(ss_ext_discount_amt) AS store_discount,
           SUM(ss_coupon_amt) AS store_coupon,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss_customer_sk
),
catalog_sales_agg AS (
    SELECT cs_bill_customer_sk AS customer_sk,
           SUM(cs_net_profit) AS catalog_net_profit,
           SUM(cs_ext_sales_price) AS catalog_sales,
           SUM(cs_quantity) AS catalog_qty,
           SUM(cs_ext_discount_amt) AS catalog_discount,
           SUM(cs_coupon_amt) AS catalog_coupon,
           COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs_bill_customer_sk
),
web_sales_agg AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_ext_sales_price) AS web_sales,
           SUM(ws_quantity) AS web_qty,
           SUM(ws_ext_discount_amt) AS web_discount,
           SUM(ws_coupon_amt) AS web_coupon,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws_bill_customer_sk
),
store_returns_agg AS (
    SELECT sr_customer_sk AS customer_sk,
           SUM(sr_net_loss) AS store_return_loss,
           SUM(sr_return_quantity) AS store_return_qty,
           COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr_customer_sk
),
catalog_returns_agg AS (
    SELECT cr_refunded_customer_sk AS customer_sk,
           SUM(cr_net_loss) AS catalog_return_loss,
           SUM(cr_return_quantity) AS catalog_return_qty,
           COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr_refunded_customer_sk
),
web_returns_agg AS (
    SELECT wr_refunded_customer_sk AS customer_sk,
           SUM(wr_net_loss) AS web_return_loss,
           SUM(wr_return_quantity) AS web_return_qty,
           COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY wr_refunded_customer_sk
),
promotion_sales AS (
    SELECT ss_customer_sk AS customer_sk, ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT cs_bill_customer_sk, cs_promo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT ws_bill_customer_sk, ws_promo_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
promotion_agg AS (
    SELECT ps.customer_sk,
           SUM(p.p_cost) AS total_promo_cost
    FROM promotion_sales ps
    JOIN promotion p ON ps.promo_sk = p.p_promo_sk
    GROUP BY ps.customer_sk
),
customer_base AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_credit_rating,
           hd.hd_income_band_sk,
           hd.hd_buy_potential,
           ca.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    cb.c_customer_id,
    cb.c_first_name,
    cb.c_last_name,
    cb.c_email_address,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.cd_credit_rating,
    cb.hd_income_band_sk,
    cb.hd_buy_potential,
    cb.ca_state,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
    COALESCE(ss.store_sales, 0) + COALESCE(cs.catalog_sales, 0) + COALESCE(ws.web_sales, 0) AS total_sales,
    COALESCE(ss.store_qty, 0) + COALESCE(cs.catalog_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
    COALESCE(ss.store_discount, 0) + COALESCE(cs.catalog_discount, 0) + COALESCE(ws.web_discount, 0) AS total_discount,
    COALESCE(ss.store_coupon, 0) + COALESCE(cs.catalog_coupon, 0) + COALESCE(ws.web_coupon, 0) AS total_coupon,
    COALESCE(sr.store_return_loss, 0) + COALESCE(cr.catalog_return_loss, 0) + COALESCE(wr.web_return_loss, 0) AS total_return_loss,
    COALESCE(ss.store_txn_cnt, 0) + COALESCE(cs.catalog_txn_cnt, 0) + COALESCE(ws.web_txn_cnt, 0) AS total_txns,
    COALESCE(sr.store_return_cnt, 0) + COALESCE(cr.catalog_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0) AS total_return_txns,
    COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) -
    (COALESCE(sr.store_return_loss, 0) + COALESCE(cr.catalog_return_loss, 0) + COALESCE(wr.web_return_loss, 0)) AS net_profit_after_returns,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) -
        (COALESCE(sr.store_return_loss, 0) + COALESCE(cr.catalog_return_loss, 0) + COALESCE(wr.web_return_loss, 0)) DESC) AS profit_rank
FROM customer_base cb
LEFT JOIN store_sales_agg ss ON cb.c_customer_sk = ss.customer_sk
LEFT JOIN catalog_sales_agg cs ON cb.c_customer_sk = cs.customer_sk
LEFT JOIN web_sales_agg ws ON cb.c_customer_sk = ws.customer_sk
LEFT JOIN store_returns_agg sr ON cb.c_customer_sk = sr.customer_sk
LEFT JOIN catalog_returns_agg cr ON cb.c_customer_sk = cr.customer_sk
LEFT JOIN web_returns_agg wr ON cb.c_customer_sk = wr.customer_sk
LEFT JOIN promotion_agg p ON cb.c_customer_sk = p.customer_sk
WHERE (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) -
      (COALESCE(sr.store_return_loss, 0) + COALESCE(cr.catalog_return_loss, 0) + COALESCE(wr.web_return_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 10
