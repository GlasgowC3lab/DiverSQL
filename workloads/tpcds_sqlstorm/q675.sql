WITH sales_union AS (
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS loc_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_id,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'web'
    FROM web_sales ws
),
returns_union AS (
    SELECT 
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_call_center_sk AS loc_sk,
        cr.cr_order_number AS order_id,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        'store'
    FROM store_returns sr
    UNION ALL
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_web_page_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        'web'
    FROM web_returns wr
),
sales_with_dims AS (
    SELECT 
        s.date_sk,
        d.d_year,
        d.d_moy,
        s.channel,
        CASE 
            WHEN s.channel = 'catalog' THEN cc.cc_state
            WHEN s.channel = 'store' THEN st.s_state
            WHEN s.channel = 'web' THEN ws.web_state
            ELSE NULL
        END AS state,
        i.i_category,
        s.item_sk,
        s.order_id,
        s.quantity,
        s.net_paid,
        s.net_profit,
        COALESCE(r.net_loss, 0) AS return_loss,
        r.quantity AS return_quantity
    FROM sales_union s
    LEFT JOIN returns_union r
      ON s.channel = r.channel 
     AND s.order_id = r.order_id 
     AND s.item_sk = r.item_sk
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN call_center cc 
      ON s.channel = 'catalog' AND s.loc_sk = cc.cc_call_center_sk
    LEFT JOIN store st 
      ON s.channel = 'store' AND s.loc_sk = st.s_store_sk
    LEFT JOIN web_site ws 
      ON s.channel = 'web' AND s.loc_sk = ws.web_site_sk
),
agg AS (
    SELECT 
        d_year,
        d_moy,
        channel,
        state,
        i_category,
        SUM(net_paid) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(return_loss) AS total_return_loss,
        SUM(quantity) AS total_quantity,
        SUM(return_quantity) AS total_return_quantity,
        AVG(CASE WHEN quantity > 0 THEN net_profit / quantity END) AS avg_profit_per_item
    FROM sales_with_dims
    GROUP BY ROLLUP (d_year, d_moy, channel, state, i_category)
)
SELECT 
    d_year,
    d_moy,
    channel,
    state,
    i_category,
    total_sales,
    total_profit,
    total_return_loss,
    total_profit - total_return_loss AS net_profit_after_returns,
    total_quantity,
    total_return_quantity,
    avg_profit_per_item,
    RANK() OVER (PARTITION BY d_year, channel ORDER BY total_profit DESC) AS profit_rank_by_category,
    SUM(total_profit) OVER (PARTITION BY channel, d_year ORDER BY d_moy 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_year_profit
FROM agg
WHERE d_year BETWEEN 2000 AND 2002
ORDER BY d_year, d_moy, channel, state, i_category
