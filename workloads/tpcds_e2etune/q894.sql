WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_sold_date_sk,
        p.p_channel_tv,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
    GROUP BY
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_sold_date_sk,
        p.p_channel_tv
),
store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS num_store_returns
    FROM store_returns sr
    GROUP BY
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_returned_date_sk
),
cat_ret_agg AS (
    SELECT
        cr.cr_refunded_cdemo_sk AS cd_demo_sk,
        cr.cr_returned_date_sk AS return_date_sk,
        SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(*) AS num_catalog_returns
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 10
      AND cr.cr_refunded_cash > 200
    GROUP BY
        cr.cr_refunded_cdemo_sk,
        cr.cr_returned_date_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_refunded_cdemo_sk AS cd_demo_sk,
        wr.wr_returned_date_sk AS return_date_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        COUNT(*) AS num_web_returns
    FROM web_returns wr
    GROUP BY
        wr.wr_refunded_cdemo_sk,
        wr.wr_returned_date_sk
)
SELECT
    s.s_state,
    sales.p_channel_tv,
    cd.cd_gender,
    cd.cd_marital_status,
    sales.ss_sold_date_sk AS sold_date_key,
    sales.total_sales_amount,
    sales.total_sales_profit,
    COALESCE(store_ret.total_store_return_amount, 0) AS total_store_return_amount,
    COALESCE(store_ret.total_store_net_loss, 0) AS total_store_net_loss,
    COALESCE(cat_ret.total_catalog_return_amount, 0) AS total_catalog_return_amount,
    COALESCE(cat_ret.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    COALESCE(web_ret.total_web_return_amount, 0) AS total_web_return_amount,
    COALESCE(web_ret.total_web_net_loss, 0) AS total_web_net_loss,
    sales.num_sales_transactions,
    COALESCE(store_ret.num_store_returns, 0) AS num_store_returns,
    COALESCE(cat_ret.num_catalog_returns, 0) AS num_catalog_returns,
    COALESCE(web_ret.num_web_returns, 0) AS num_web_returns
FROM sales_agg sales
JOIN store s
    ON sales.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
    ON sales.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_ret_agg store_ret
    ON store_ret.sr_store_sk = s.s_store_sk
   AND store_ret.sr_cdemo_sk = cd.cd_demo_sk
   AND store_ret.sr_returned_date_sk = sales.ss_sold_date_sk
LEFT JOIN cat_ret_agg cat_ret
    ON cat_ret.cd_demo_sk = cd.cd_demo_sk
   AND cat_ret.return_date_sk = sales.ss_sold_date_sk
LEFT JOIN web_ret_agg web_ret
    ON web_ret.cd_demo_sk = cd.cd_demo_sk
   AND web_ret.return_date_sk = sales.ss_sold_date_sk
WHERE sales.total_sales_profit > 10000
ORDER BY sales.total_sales_amount DESC
LIMIT 100
