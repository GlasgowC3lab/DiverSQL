WITH agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        s.s_store_name AS store_name,
        d_closed.d_current_month AS closed_month,
        d_closed.d_year AS closed_year,
        d_open.d_current_month AS open_month,
        d_open.d_year AS open_year,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM call_center cc
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_closed.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_closed.d_date_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    GROUP BY
        cc.cc_name,
        s.s_store_name,
        d_closed.d_current_month,
        d_closed.d_year,
        d_open.d_current_month,
        d_open.d_year
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    agg.call_center_name,
    agg.store_name,
    agg.closed_month,
    agg.closed_year,
    agg.open_month,
    agg.open_year,
    agg.total_sales_profit,
    agg.total_return_loss,
    agg.total_sales_profit - agg.total_return_loss AS net_profit_after_returns,
    agg.num_orders,
    agg.total_quantity_sold,
    agg.total_quantity_returned,
    agg.avg_discount_amount,
    agg.max_sales_price,
    agg.min_sales_price,
    ROW_NUMBER() OVER (PARTITION BY agg.closed_year, agg.closed_month ORDER BY agg.total_sales_profit DESC) AS profit_rank_in_month
FROM agg
ORDER BY net_profit_after_returns DESC
LIMIT 100
