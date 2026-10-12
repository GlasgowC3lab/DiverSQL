WITH agg AS (
    SELECT
        s.s_state,
        d.d_year,
        CASE 
            WHEN cr.cr_return_quantity > 5 THEN 'Large' 
            ELSE 'Small' 
        END AS return_size_category,
        (cr.cr_return_quantity * ws.ws_quantity) AS qty_product,
        COUNT(DISTINCT cr.cr_order_number) AS num_catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS num_web_return_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ws.ws_quantity) AS avg_web_quantity,
        SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount_inc_tax
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY
        s.s_state,
        d.d_year,
        CASE 
            WHEN cr.cr_return_quantity > 5 THEN 'Large' 
            ELSE 'Small' 
        END,
        (cr.cr_return_quantity * ws.ws_quantity)
)
SELECT
    s_state,
    d_year,
    return_size_category,
    qty_product,
    num_catalog_orders,
    num_web_return_orders,
    total_catalog_net_loss,
    total_web_net_loss,
    total_web_net_profit,
    total_web_sales,
    avg_web_quantity,
    total_catalog_return_amount,
    total_web_return_amount_inc_tax,
    (total_catalog_net_loss + total_web_net_loss) / NULLIF(total_web_net_profit, 0) AS loss_to_profit_ratio,
    CASE 
        WHEN total_web_sales > 100000 THEN 'HighSales' 
        ELSE 'LowSales' 
    END AS sales_category
FROM agg
ORDER BY s_state, d_year, return_size_category, qty_product
LIMIT 100
