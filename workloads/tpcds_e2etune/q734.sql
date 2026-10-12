WITH returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_order_number,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY
        cr.cr_item_sk,
        cr.cr_order_number
)
SELECT
    i.i_brand,
    w.w_state,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(r.total_return_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_quantity) AS total_quantity_sold
FROM
    catalog_sales cs
JOIN
    item i
        ON cs.cs_item_sk = i.i_item_sk
JOIN
    warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN
    returns_agg r
        ON cs.cs_item_sk = r.cr_item_sk
        AND cs.cs_order_number = r.cr_order_number
WHERE
    cs.cs_sold_date_sk BETWEEN 2450900 AND 2451100
    AND i.i_brand IN ('Brand#12', 'Brand#23', 'Brand#45')
GROUP BY
    i.i_brand,
    w.w_state
HAVING
    SUM(cs.cs_net_profit) - COALESCE(SUM(r.total_return_loss), 0) > 0
ORDER BY
    net_profit_after_returns DESC
LIMIT 10
