WITH sales AS (
 SELECT cs.cs_sold_date_sk AS date_sk,
        cs.cs_call_center_sk AS channel_id,
        'catalog' AS channel_type,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity
 FROM catalog_sales cs
 UNION ALL
 SELECT ss.ss_sold_date_sk,
        ss.ss_store_sk,
        'store',
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity
 FROM store_sales ss
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        'web',
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity
 FROM web_sales ws
),
returns AS (
 SELECT cr.cr_returned_date_sk AS date_sk,
        cr.cr_call_center_sk AS channel_id,
        'catalog' AS channel_type,
        cr.cr_item_sk AS item_sk,
        -cr.cr_refunded_cash AS net_paid,
        -cr.cr_net_loss AS net_profit,
        -cr.cr_return_quantity AS quantity
 FROM catalog_returns cr
 UNION ALL
 SELECT sr.sr_returned_date_sk,
        sr.sr_store_sk,
        'store',
        sr.sr_item_sk,
        -sr.sr_refunded_cash,
        -sr.sr_net_loss,
        -sr.sr_return_quantity
 FROM store_returns sr
 UNION ALL
 SELECT wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        'web',
        wr.wr_item_sk,
        -wr.wr_refunded_cash,
        -wr.wr_net_loss,
        -wr.wr_return_quantity
 FROM web_returns wr
),
combined AS (
 SELECT * FROM sales
 UNION ALL
 SELECT * FROM returns
)
SELECT d.d_year,
       c.channel_type,
       i.i_category,
       SUM(c.net_paid) AS total_net_paid,
       SUM(c.net_profit) AS total_net_profit,
       SUM(c.quantity) AS total_quantity
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, c.channel_type, i.i_category
ORDER BY d.d_year, total_net_paid DESC
