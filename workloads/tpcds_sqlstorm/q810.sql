WITH sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           NULL,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           NULL,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
),
returns AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_store_sk AS store_sk,
           sr.sr_item_sk AS item_sk,
           -sr.sr_return_quantity AS quantity,
           -sr.sr_refunded_cash AS net_paid,
           -sr.sr_net_loss AS net_profit
    FROM store_returns sr
    UNION ALL
    SELECT cr.cr_returned_date_sk,
           NULL,
           cr.cr_item_sk,
           -cr.cr_return_quantity,
           -cr.cr_refunded_cash,
           -cr.cr_net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           NULL,
           wr.wr_item_sk,
           -wr.wr_return_quantity,
           -wr.wr_refunded_cash,
           -wr.wr_net_loss
    FROM web_returns wr
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT d.d_year,
       d.d_month_seq,
       st.s_store_name,
       i.i_category,
       SUM(c.quantity) AS total_quantity,
       SUM(c.net_paid) AS total_revenue,
       SUM(c.net_profit) AS total_profit
FROM combined c
LEFT JOIN date_dim d ON c.date_sk = d.d_date_sk
LEFT JOIN store st ON c.store_sk = st.s_store_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_month_seq, st.s_store_name, i.i_category
ORDER BY total_revenue DESC
