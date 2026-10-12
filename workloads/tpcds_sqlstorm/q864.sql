WITH combined AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    UNION ALL
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_store_sk AS store_sk,
           sr.sr_item_sk AS item_sk,
           -sr.sr_net_loss AS profit
    FROM store_returns sr
)
SELECT d.d_year,
       s.s_state,
       i.i_category,
       SUM(c.profit) AS net_profit
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN store s ON c.store_sk = s.s_store_sk
JOIN item i ON c.item_sk = i.i_item_sk
GROUP BY d.d_year, s.s_state, i.i_category
ORDER BY d.d_year, s.s_state, i.i_category
