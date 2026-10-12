WITH joined_data AS (
    SELECT
        ca.ca_state,
        i.i_category,
        ss.ss_net_profit AS store_profit,
        cs.cs_net_profit AS catalog_profit,
        ws.ws_net_profit AS web_profit,
        wr.wr_net_loss AS return_loss
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        cs.cs_wholesale_cost > 20
        AND ws.ws_ext_tax >= 17.5
        AND ca.ca_state = 'CA'
        AND ws.ws_warehouse_sk IN (1, 8, 15)
),
agg AS (
    SELECT
        ca_state,
        i_category,
        SUM(store_profit) AS total_store_profit,
        SUM(catalog_profit) AS total_catalog_profit,
        SUM(web_profit) AS total_web_profit,
        SUM(return_loss) AS total_return_loss,
        (SUM(store_profit) + SUM(catalog_profit) + SUM(web_profit) - SUM(return_loss)) AS overall_profit
    FROM joined_data
    GROUP BY ca_state, i_category
    HAVING (SUM(store_profit) + SUM(catalog_profit) + SUM(web_profit) - SUM(return_loss)) > 1000
)
SELECT
    ca_state,
    i_category,
    total_store_profit,
    total_catalog_profit,
    total_web_profit,
    total_return_loss,
    overall_profit,
    SUM(overall_profit) OVER (ORDER BY overall_profit DESC ROWS UNBOUNDED PRECEDING) AS running_total
FROM agg
ORDER BY overall_profit DESC
LIMIT 100
