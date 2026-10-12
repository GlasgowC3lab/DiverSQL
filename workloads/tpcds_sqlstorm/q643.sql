WITH cat_return_agg AS (
    SELECT cr_order_number AS order_number,
           cr_item_sk AS item_sk,
           SUM(cr_net_loss) AS return_loss
    FROM catalog_returns
    GROUP BY cr_order_number, cr_item_sk
),
store_return_agg AS (
    SELECT sr_ticket_number AS ticket_number,
           sr_item_sk AS item_sk,
           SUM(sr_net_loss) AS return_loss
    FROM store_returns
    GROUP BY sr_ticket_number, sr_item_sk
),
web_return_agg AS (
    SELECT wr_order_number AS order_number,
           wr_item_sk AS item_sk,
           SUM(wr_net_loss) AS return_loss
    FROM web_returns
    GROUP BY wr_order_number, wr_item_sk
),
cat_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_quarter_seq AS quarter,
           i.i_category AS category,
           'Catalog' AS channel,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
           SUM(cs.cs_net_profit) AS sales_profit,
           SUM(COALESCE(cr.return_loss, 0)) AS return_loss,
           SUM(cs.cs_net_profit) - SUM(COALESCE(cr.return_loss, 0)) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN cat_return_agg cr ON cs.cs_order_number = cr.order_number AND cs.cs_item_sk = cr.item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
store_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_quarter_seq AS quarter,
           i.i_category AS category,
           'Store' AS channel,
           COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
           SUM(ss.ss_net_profit) AS sales_profit,
           SUM(COALESCE(sr.return_loss, 0)) AS return_loss,
           SUM(ss.ss_net_profit) - SUM(COALESCE(sr.return_loss, 0)) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_return_agg sr ON ss.ss_ticket_number = sr.ticket_number AND ss.ss_item_sk = sr.item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_quarter_seq AS quarter,
           i.i_category AS category,
           'Web' AS channel,
           COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
           SUM(ws.ws_net_profit) AS sales_profit,
           SUM(COALESCE(wr.return_loss, 0)) AS return_loss,
           SUM(ws.ws_net_profit) - SUM(COALESCE(wr.return_loss, 0)) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_return_agg wr ON ws.ws_order_number = wr.order_number AND ws.ws_item_sk = wr.item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
combined_sales AS (
    SELECT * FROM cat_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
ranking AS (
    SELECT
        year,
        quarter,
        channel,
        category,
        order_cnt,
        sales_profit,
        return_loss,
        net_profit,
        CASE WHEN order_cnt = 0 THEN NULL ELSE round(net_profit / order_cnt, 2) END AS avg_profit_per_order,
        ROW_NUMBER() OVER (PARTITION BY year, quarter, channel ORDER BY net_profit DESC) AS cat_rank,
        ROW_NUMBER() OVER (PARTITION BY year, quarter ORDER BY net_profit DESC) AS channel_rank
    FROM combined_sales
)
SELECT
    year,
    quarter,
    channel,
    category,
    order_cnt,
    sales_profit,
    return_loss,
    net_profit,
    avg_profit_per_order
FROM ranking
WHERE cat_rank = 1
   OR channel_rank = 1
ORDER BY year DESC, quarter DESC, channel, net_profit DESC
LIMIT 100
