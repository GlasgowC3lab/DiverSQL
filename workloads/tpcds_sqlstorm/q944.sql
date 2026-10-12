WITH
sales_union AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        'store' AS channel,
        s.s_store_id AS channel_id,
        i.i_category,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_ticket_number AS order_key
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month,
        'catalog' AS channel,
        cc.cc_call_center_id AS channel_id,
        i.i_category,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month,
        'web' AS channel,
        wp.wp_web_page_id AS channel_id,
        i.i_category,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
returns_union AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        'store' AS channel,
        s.s_store_id AS channel_id,
        i.i_category,
        sr.sr_return_quantity AS return_qty,
        sr.sr_net_loss AS net_loss,
        sr.sr_ticket_number AS order_key
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month,
        'catalog' AS channel,
        cc.cc_call_center_id AS channel_id,
        i.i_category,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month,
        'web' AS channel,
        wp.wp_web_page_id AS channel_id,
        i.i_category,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
agg_sales AS (
    SELECT
        d_year,
        month,
        channel,
        channel_id,
        i_category,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT order_key) AS total_orders
    FROM sales_union
    GROUP BY d_year, month, channel, channel_id, i_category
),
agg_returns AS (
    SELECT
        d_year,
        month,
        channel,
        channel_id,
        i_category,
        SUM(net_loss) AS total_return_loss,
        SUM(return_qty) AS total_return_qty,
        COUNT(DISTINCT order_key) AS total_return_orders
    FROM returns_union
    GROUP BY d_year, month, channel, channel_id, i_category
)
SELECT
    s.d_year,
    s.month,
    s.channel,
    s.channel_id,
    s.i_category,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) / NULLIF(s.total_sales, 0) AS profit_margin,
    s.total_quantity,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.total_orders,
    COALESCE(r.total_return_orders, 0) AS total_return_orders,
    ROW_NUMBER() OVER (PARTITION BY s.d_year, s.month, s.channel ORDER BY s.total_sales - COALESCE(r.total_return_loss, 0) DESC) AS channel_rank,
    SUM(s.total_sales - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.channel_id ORDER BY s.d_year, s.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_3_month_sales
FROM agg_sales s
LEFT JOIN agg_returns r
    ON s.d_year = r.d_year
   AND s.month = r.month
   AND s.channel = r.channel
   AND s.channel_id = r.channel_id
   AND s.i_category = r.i_category
WHERE s.d_year BETWEEN 1999 AND 2001
ORDER BY s.d_year, s.month, s.channel, net_sales DESC
LIMIT 200
