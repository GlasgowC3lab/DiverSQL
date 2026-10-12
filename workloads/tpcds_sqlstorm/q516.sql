WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS sales_amount,
        'store' AS channel,
        ss.ss_store_sk AS channel_id
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        'web' AS channel,
        ws.ws_web_site_sk
    FROM web_sales ws
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        'catalog' AS channel,
        cs.cs_call_center_sk
    FROM catalog_sales cs
),
returns_union AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        -sr.sr_net_loss AS net_profit,
        -sr.sr_return_amt AS sales_amount,
        'store' AS channel,
        sr.sr_store_sk AS channel_id
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        -wr.wr_net_loss,
        -wr.wr_return_amt,
        'web' AS channel,
        wr.wr_web_page_sk
    FROM web_returns wr
    UNION ALL
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        -cr.cr_net_loss,
        -cr.cr_return_amount,
        'catalog' AS channel,
        cr.cr_call_center_sk
    FROM catalog_returns cr
),
daily_item_sales AS (
    SELECT
        d.d_year,
        d.d_moy AS sale_month,
        s.channel,
        i.i_item_id,
        i.i_product_name,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.sales_amount) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, d.d_moy, s.channel, i.i_item_id, i.i_product_name
),
daily_item_returns AS (
    SELECT
        d.d_year,
        d.d_moy AS sale_month,
        r.channel,
        i.i_item_id,
        i.i_product_name,
        SUM(r.net_profit) AS total_return_profit,
        SUM(r.sales_amount) AS total_return_sales,
        COUNT(*) AS return_cnt
    FROM returns_union r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, d.d_moy, r.channel, i.i_item_id, i.i_product_name
),
combined_daily_item AS (
    SELECT
        s.d_year,
        s.sale_month,
        s.channel,
        s.i_item_id,
        s.i_product_name,
        s.total_net_profit + COALESCE(r.total_return_profit, 0) AS net_profit_adj,
        s.total_sales + COALESCE(r.total_return_sales, 0) AS sales_adj,
        s.sales_cnt + COALESCE(r.return_cnt, 0) AS txn_cnt
    FROM daily_item_sales s
    LEFT JOIN daily_item_returns r
        ON s.d_year = r.d_year
        AND s.sale_month = r.sale_month
        AND s.channel = r.channel
        AND s.i_item_id = r.i_item_id
),
ranked_items AS (
    SELECT
        d_year,
        sale_month,
        channel,
        i_item_id,
        i_product_name,
        net_profit_adj,
        sales_adj,
        txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY d_year, sale_month, channel ORDER BY net_profit_adj DESC) AS rank_by_profit,
        SUM(net_profit_adj) OVER (PARTITION BY d_year, sale_month, channel ORDER BY net_profit_adj DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
    FROM combined_daily_item
)
SELECT
    d_year,
    sale_month,
    channel,
    i_item_id,
    i_product_name,
    net_profit_adj,
    sales_adj,
    txn_cnt,
    rank_by_profit,
    cum_profit
FROM ranked_items
WHERE rank_by_profit <= 10
ORDER BY d_year, sale_month, channel, rank_by_profit
