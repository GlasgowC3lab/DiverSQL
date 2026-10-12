WITH sales AS (
    SELECT
        'store' AS channel,
        ss.ss_store_sk AS channel_id,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS profit,
        ss.ss_net_paid AS revenue,
        ss.ss_ext_discount_amt AS discount,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_call_center_sk AS channel_id,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS profit,
        cs.cs_net_paid AS revenue,
        cs.cs_ext_discount_amt AS discount,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_web_page_sk AS channel_id,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS profit,
        ws.ws_net_paid AS revenue,
        ws.ws_ext_discount_amt AS discount,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
),
returns AS (
    SELECT
        'store' AS channel,
        sr.sr_store_sk AS channel_id,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_net_loss AS loss
    FROM store_returns sr
    UNION ALL
    SELECT
        'catalog' AS channel,
        cr.cr_call_center_sk AS channel_id,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS loss
    FROM catalog_returns cr
    UNION ALL
    SELECT
        'web' AS channel,
        wr.wr_web_page_sk AS channel_id,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS quantity,
        wr.wr_net_loss AS loss
    FROM web_returns wr
),
agg AS (
    SELECT
        s.channel,
        s.channel_id,
        d.d_year,
        i.i_brand,
        i.i_category,
        SUM(s.quantity) AS total_quantity,
        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit,
        SUM(s.discount) AS total_discount,
        COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
        COALESCE(SUM(r.loss), 0) AS total_returns_loss,
        SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    LEFT JOIN returns r
        ON r.channel = s.channel
        AND r.channel_id = s.channel_id
        AND r.date_sk = s.date_sk
        AND r.item_sk = s.item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY
        s.channel,
        s.channel_id,
        d.d_year,
        i.i_brand,
        i.i_category
)
SELECT
    channel,
    channel_id,
    d_year,
    i_brand,
    i_category,
    total_quantity,
    total_revenue,
    total_profit,
    total_discount,
    total_returns_loss,
    distinct_items_sold,
    total_promo_cost,
    profit_rank
FROM (
    SELECT
        channel,
        channel_id,
        d_year,
        i_brand,
        i_category,
        total_quantity,
        total_revenue,
        total_profit,
        total_discount,
        total_returns_loss,
        distinct_items_sold,
        total_promo_cost,
        ROW_NUMBER() OVER (PARTITION BY channel, channel_id, d_year ORDER BY total_profit DESC) AS profit_rank
    FROM agg
) t
WHERE profit_rank <= 5
ORDER BY channel, channel_id, d_year, profit_rank
