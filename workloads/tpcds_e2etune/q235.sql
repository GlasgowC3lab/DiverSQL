SELECT
    r.r_reason_desc AS return_reason,
    sm.sm_type AS ship_mode_type,
    i.i_brand AS item_brand,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cs.cs_net_paid_inc_tax), 0) AS return_to_sales_ratio,
    RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
FROM
    catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_ship_mode_sk = cs.cs_ship_mode_sk
WHERE
    cr.cr_return_quantity > 20
    AND i.i_category = 'Electronics'
    AND sm.sm_type IN ('AIR', 'GROUND')
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
GROUP BY
    r.r_reason_desc,
    sm.sm_type,
    i.i_brand
HAVING
    SUM(cr.cr_return_amount) > 5000
ORDER BY
    total_net_loss DESC
LIMIT 50
