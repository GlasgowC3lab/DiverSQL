-- Goal: Summarize catalog sales and store returns by product and hour, flag profitable sales and loss returns, exclude items that also have web returns, and demonstrate deep joins, alias reuse, a full outer join, a NOT EXISTS anti‑join, CASE logic, and a UNION distinct aggregation.
WITH sales_cte AS (
    SELECT
        cs.cs_item_sk                     AS item_sk,
        i_sales.i_product_name            AS product_name,
        td_sales.t_hour                   AS hour_of_day,
        cs.cs_net_paid_inc_ship           AS sales_amount,
        cs.cs_order_number                AS order_number,
        cs.cs_net_profit                  AS net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        sm.sm_type                        AS ship_type,
        ca_bill.ca_state                  AS billing_state,
        ca_ship.ca_state                  AS shipping_state
    FROM catalog_sales cs
    JOIN time_dim td_sales
        ON cs.cs_sold_time_sk = td_sales.t_time_sk
    JOIN item i_sales
        ON cs.cs_item_sk = i_sales.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_ext_sales_price > 1000
),
returns_cte AS (
    SELECT
        sr.sr_item_sk                     AS item_sk,
        i_ret.i_product_name              AS product_name,
        td_ret.t_hour                     AS hour_of_day,
        sr.sr_return_amt                  AS return_amount,
        sr.sr_ticket_number               AS return_ticket,
        sr.sr_net_loss                    AS net_loss,
        CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Neutral' END AS loss_category,
        r.r_reason_desc                   AS return_reason,
        s.s_store_name                    AS store_name,
        ca_addr.ca_state                  AS store_state
    FROM store_returns sr
    FULL OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    JOIN item i_ret
        ON sr.sr_item_sk = i_ret.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_addr
        ON sr.sr_addr_sk = ca_addr.ca_address_sk
    WHERE sr.sr_return_quantity > 0
)
SELECT
    product_name,
    hour_of_day,
    SUM(sales_amount)                     AS total_sales_amount,
    SUM(return_amount)                    AS total_return_amount,
    COUNT(DISTINCT order_number)          AS distinct_orders,
    COUNT(DISTINCT return_ticket)         AS distinct_returns,
    SUM(CASE WHEN profit_category = 'Profitable' THEN sales_amount ELSE 0 END) AS profitable_sales,
    SUM(CASE WHEN loss_category = 'Loss' THEN return_amount ELSE 0 END)          AS loss_returns
FROM (
    SELECT
        item_sk,
        product_name,
        hour_of_day,
        sales_amount,
        0.0               AS return_amount,
        order_number,
        NULL              AS return_ticket,
        profit_category,
        NULL              AS loss_category
    FROM sales_cte
    UNION DISTINCT
    SELECT
        item_sk,
        product_name,
        hour_of_day,
        0.0               AS sales_amount,
        return_amount,
        NULL              AS order_number,
        return_ticket,
        NULL              AS profit_category,
        loss_category
    FROM returns_cte
) AS combined
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_item_sk = combined.item_sk
      AND wr.wr_return_quantity > 0
)
GROUP BY product_name, hour_of_day, profit_category, loss_category
ORDER BY total_sales_amount DESC
LIMIT 100
