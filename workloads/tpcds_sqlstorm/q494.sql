WITH
sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_promo_sk,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_promo_sk,
           'web'
    FROM web_sales ws
),
sales_enriched AS (
    SELECT su.sold_date_sk,
           d.d_date,
           d.d_year,
           i.i_category,
           i.i_category_id,
           i.i_item_id,
           i.i_product_name,
           su.item_sk,
           su.cust_sk,
           su.quantity,
           su.net_paid,
           su.net_profit,
           su.promo_sk,
           su.channel,
           p.p_discount_active,
           p.p_cost AS promo_cost
    FROM sales_union su
    LEFT JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
returns_union AS (
    SELECT sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_customer_sk AS cust_sk,
           sr.sr_net_loss AS net_loss,
           'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_refunded_customer_sk,
           cr.cr_net_loss,
           'catalog'
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_refunded_customer_sk,
           wr.wr_net_loss,
           'web'
    FROM web_returns wr
),
returns_enriched AS (
    SELECT ru.returned_date_sk,
           d.d_date,
           d.d_year,
           i.i_category,
           i.i_category_id,
           i.i_item_id,
           i.i_product_name,
           ru.item_sk,
           ru.cust_sk,
           ru.net_loss,
           ru.channel
    FROM returns_union ru
    LEFT JOIN date_dim d ON ru.returned_date_sk = d.d_date_sk
    LEFT JOIN item i ON ru.item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
category_sales_raw AS (
    SELECT i_category,
           channel,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit,
           COUNT(*) AS transaction_count
    FROM sales_enriched
    GROUP BY GROUPING SETS ((i_category, channel), (i_category))
),
category_returns_raw AS (
    SELECT i_category,
           channel,
           SUM(net_loss) AS total_return_loss,
           COUNT(*) AS return_count
    FROM returns_enriched
    GROUP BY GROUPING SETS ((i_category, channel), (i_category))
),
category_sales AS (
    SELECT i_category,
           COALESCE(channel, 'ALL') AS channel,
           total_net_paid,
           total_net_profit,
           transaction_count
    FROM category_sales_raw
),
category_returns AS (
    SELECT i_category,
           COALESCE(channel, 'ALL') AS channel,
           total_return_loss,
           return_count
    FROM category_returns_raw
),
category_combined AS (
    SELECT
        cs.i_category,
        cs.channel,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.transaction_count,
        COALESCE(cr.total_return_loss, 0) AS total_return_loss,
        COALESCE(cr.return_count, 0) AS return_count,
        cs.total_net_paid - COALESCE(cr.total_return_loss, 0) AS net_paid_after_returns,
        cs.total_net_profit - COALESCE(cr.total_return_loss, 0) AS net_profit_after_returns
    FROM category_sales cs
    LEFT JOIN category_returns cr
        ON cs.i_category = cr.i_category AND cs.channel = cr.channel
),
final_stats AS (
    SELECT
        i_category,
        channel,
        total_net_paid,
        total_net_profit,
        total_return_loss,
        net_paid_after_returns,
        net_profit_after_returns,
        transaction_count,
        return_count,
        RANK() OVER (PARTITION BY channel ORDER BY net_paid_after_returns DESC) AS revenue_rank,
        RANK() OVER (PARTITION BY channel ORDER BY net_profit_after_returns DESC) AS profit_rank,
        approx_percentile(net_paid_after_returns, 0.5) OVER (PARTITION BY channel) AS median_net_paid_after_returns
    FROM category_combined
)
SELECT
    i_category,
    channel,
    total_net_paid,
    total_net_profit,
    total_return_loss,
    net_paid_after_returns,
    net_profit_after_returns,
    transaction_count,
    return_count,
    revenue_rank,
    profit_rank,
    median_net_paid_after_returns
FROM final_stats
ORDER BY channel, revenue_rank
LIMIT 100
