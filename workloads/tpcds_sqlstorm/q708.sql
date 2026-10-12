WITH sales_union AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_net_profit AS net_profit,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_site_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        NULL,
        ss.ss_store_sk,
        NULL,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        NULL,
        NULL,
        ws.ws_web_site_sk,
        'web'
    FROM web_sales ws
),
returns_union AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'store'
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'web'
    FROM web_returns wr
),
sales_agg AS (
    SELECT
        s.item_sk,
        s.date_sk,
        s.channel,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.net_paid_inc_tax) AS total_net_paid_inc_tax,
        MAX(s.call_center_sk) AS call_center_sk,
        MAX(s.store_sk) AS store_sk,
        MAX(s.web_site_sk) AS web_site_sk
    FROM sales_union s
    GROUP BY s.item_sk, s.date_sk, s.channel
),
returns_agg AS (
    SELECT
        r.item_sk,
        r.date_sk,
        r.channel,
        SUM(r.quantity) AS total_ret_quantity,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.net_loss) AS total_return_net_loss
    FROM returns_union r
    GROUP BY r.item_sk, r.date_sk, r.channel
),
final_sales AS (
    SELECT
        sa.item_sk,
        sa.date_sk,
        sa.channel,
        sa.total_quantity,
        sa.total_net_paid,
        sa.total_net_profit,
        ra.total_ret_quantity,
        ra.total_return_amount,
        ra.total_return_net_loss,
        COALESCE(ra.total_return_net_loss, 0) AS return_loss,
        (sa.total_net_profit - COALESCE(ra.total_return_net_loss, 0)) AS net_profit_adj,
        i.i_category,
        i.i_class,
        i.i_product_name,
        d.d_year,
        d.d_moy,
        CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_moy AS varchar), 2, '0')) AS year_month,
        cc.cc_name AS call_center_name,
        st.s_store_name AS store_name,
        wsite.web_name AS web_site_name
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.item_sk = ra.item_sk
        AND sa.date_sk = ra.date_sk
        AND sa.channel = ra.channel
    JOIN item i ON sa.item_sk = i.i_item_sk
    JOIN date_dim d ON sa.date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON sa.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store st ON sa.store_sk = st.s_store_sk
    LEFT JOIN web_site wsite ON sa.web_site_sk = wsite.web_site_sk
),
aggregated AS (
    SELECT
        year_month,
        channel,
        i_category,
        i_class,
        i_product_name,
        SUM(total_quantity) AS total_quantity_sold,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_net_profit) AS total_gross_profit,
        SUM(total_ret_quantity) AS total_quantity_returned,
        SUM(total_return_amount) AS total_return_amount,
        SUM(return_loss) AS total_return_loss,
        SUM(net_profit_adj) AS total_net_profit
    FROM final_sales
    GROUP BY
        year_month,
        channel,
        i_category,
        i_class,
        i_product_name
    HAVING SUM(net_profit_adj) > 0
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS channel_profit_rank
    FROM aggregated
)
SELECT
    year_month,
    channel,
    i_category,
    i_class,
    i_product_name,
    total_quantity_sold,
    total_net_paid,
    total_gross_profit,
    total_quantity_returned,
    total_return_amount,
    total_return_loss,
    total_net_profit,
    channel_profit_rank
FROM ranked
ORDER BY total_net_profit DESC
LIMIT 50
