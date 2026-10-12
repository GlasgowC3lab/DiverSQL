WITH aggregated AS (
    SELECT
        d_sold.d_date AS sale_date,
        d_ship.d_date AS ship_date,
        d_return.d_date AS return_date,
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month_seq,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT s.s_store_sk) AS closed_stores,
        SUM(s.s_floor_space) AS total_closed_store_floor_space,
        (SUM(ws.ws_net_profit) - (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss))) AS net_gain
    FROM catalog_returns cr
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    GROUP BY
        d_sold.d_date,
        d_ship.d_date,
        d_return.d_date,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    sale_date,
    ship_date,
    return_date,
    sale_year,
    sale_month_seq,
    total_web_sales,
    total_web_profit,
    total_catalog_return_loss,
    total_web_return_loss,
    closed_stores,
    total_closed_store_floor_space,
    net_gain,
    RANK() OVER (ORDER BY total_web_profit DESC) AS profit_rank
FROM aggregated
ORDER BY net_gain DESC
LIMIT 100
