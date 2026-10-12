WITH
store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit,
        SUM(ss.ss_ext_sales_price) - COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit,
        SUM(cs.cs_ext_sales_price) - COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit,
        SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    channel,
    d_year,
    month_seq,
    i_category,
    net_profit,
    sales_amount,
    orders,
    distinct_customers,
    net_profit / NULLIF(sales_amount, 0) AS profit_margin,
    total_channel_profit,
    net_profit / NULLIF(total_channel_profit, 0) AS profit_share
FROM (
    SELECT
        c.*,
        SUM(net_profit) OVER (PARTITION BY channel, d_year, month_seq) AS total_channel_profit,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year, month_seq ORDER BY net_profit DESC) AS rn
    FROM combined c
) t
WHERE rn <= 5
ORDER BY channel, d_year, month_seq, net_profit DESC
