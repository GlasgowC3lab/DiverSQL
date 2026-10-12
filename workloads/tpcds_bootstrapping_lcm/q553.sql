SELECT
    call_center_name,
    store_name,
    sales_year,
    sales_month,
    total_sales_net_paid_inc_tax,
    total_sales_ext_price,
    total_sales_tax,
    total_return_net_loss,
    net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM (
    SELECT
        cc.cc_name AS call_center_name,
        s.s_store_name AS store_name,
        d_main.d_year AS sales_year,
        d_main.d_moy AS sales_month,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_net_paid_inc_tax,
        SUM(ws.ws_ext_sales_price) AS total_sales_ext_price,
        SUM(ws.ws_ext_tax) AS total_sales_tax,
        SUM(wr.wr_net_loss) AS total_return_net_loss,
        SUM(ws.ws_net_paid_inc_tax) - SUM(wr.wr_net_loss) AS net_profit_after_returns
    FROM
        date_dim d_main
        JOIN call_center cc ON cc.cc_closed_date_sk = d_main.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d_main.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d_main.d_date_sk
        JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                               AND wr.wr_order_number = ws.ws_order_number
        JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
        JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
        JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE
        d_main.d_year = 2001
    GROUP BY
        cc.cc_name,
        s.s_store_name,
        d_main.d_year,
        d_main.d_moy
) t
ORDER BY
    net_profit_after_returns DESC
LIMIT 100
