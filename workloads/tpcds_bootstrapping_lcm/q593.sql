WITH
    catalog_returns_agg AS (
        SELECT
            cr_returned_date_sk AS d_date_sk,
            COUNT(*) AS catalog_return_cnt,
            SUM(cr_return_amount) AS catalog_return_amount,
            SUM(cr_net_loss) AS catalog_net_loss
        FROM catalog_returns
        GROUP BY cr_returned_date_sk
    ),
    web_sales_agg AS (
        SELECT
            ws_sold_date_sk AS d_date_sk,
            COUNT(*) AS web_sales_cnt,
            SUM(ws_ext_sales_price) AS web_sales_ext_sales,
            SUM(ws_net_profit) AS web_sales_net_profit
        FROM web_sales
        GROUP BY ws_sold_date_sk
    ),
    web_returns_sales_agg AS (
        SELECT
            wr.wr_returned_date_sk AS d_date_sk,
            COUNT(*) AS returned_sales_cnt,
            SUM(wr.wr_return_amt) AS total_return_amount,
            SUM(ws.ws_net_profit) AS total_original_profit,
            SUM(ws.ws_net_profit - wr.wr_return_amt) AS net_profit_loss_due_to_return
        FROM web_returns wr
        JOIN web_sales ws
            ON wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_order_number = ws.ws_order_number
        GROUP BY wr.wr_returned_date_sk
    ),
    store_agg AS (
        SELECT
            s_closed_date_sk AS d_date_sk,
            COUNT(*) AS closed_store_cnt,
            AVG(s_floor_space) AS avg_floor_space
        FROM store
        GROUP BY s_closed_date_sk
    )
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    cr.catalog_return_cnt,
    cr.catalog_return_amount,
    cr.catalog_net_loss,
    ws.web_sales_cnt,
    ws.web_sales_ext_sales,
    ws.web_sales_net_profit,
    wrs.returned_sales_cnt,
    wrs.total_return_amount,
    wrs.net_profit_loss_due_to_return,
    s.closed_store_cnt,
    s.avg_floor_space,
    (COALESCE(ws.web_sales_net_profit, 0)
     - COALESCE(cr.catalog_net_loss, 0)
     - COALESCE(wrs.net_profit_loss_due_to_return, 0)) AS overall_net_adjusted,
    RANK() OVER (ORDER BY (COALESCE(ws.web_sales_net_profit, 0)
                           - COALESCE(cr.catalog_net_loss, 0)
                           - COALESCE(wrs.net_profit_loss_due_to_return, 0)) DESC) AS net_rank
FROM date_dim d
LEFT JOIN catalog_returns_agg cr ON cr.d_date_sk = d.d_date_sk
LEFT JOIN web_sales_agg ws       ON ws.d_date_sk = d.d_date_sk
LEFT JOIN web_returns_sales_agg wrs ON wrs.d_date_sk = d.d_date_sk
LEFT JOIN store_agg s           ON s.d_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
ORDER BY net_rank
LIMIT 100
