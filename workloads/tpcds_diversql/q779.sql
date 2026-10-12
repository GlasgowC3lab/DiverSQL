WITH full_cr_cs AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cr.cr_refunded_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_addr_sk,
        cs.cs_bill_cdemo_sk
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
)
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    COALESCE(full_cr_cs.cr_return_quantity, 0) AS return_quantity,
    COALESCE(full_cr_cs.cs_quantity, 0) AS sale_quantity,
    COALESCE(full_cr_cs.cs_sales_price, 0) * COALESCE(full_cr_cs.cs_quantity, 0) AS total_sales_amount,
    CASE WHEN full_cr_cs.cr_refunded_cash > 500 THEN 'High' ELSE 'Low' END AS refund_level,
    inv_agg.total_quantity_on_hand,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY full_cr_cs.cs_net_profit DESC) AS brand_profit_rank,
    ca.ca_state,
    cd.cd_purchase_estimate
FROM full_cr_cs
LEFT JOIN item i
    ON full_cr_cs.cs_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
) inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk
LEFT JOIN customer_address ca
    ON full_cr_cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON full_cr_cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    i.i_current_price > 20
    AND ca.ca_state = 'CA'
    AND cd.cd_purchase_estimate > 4000
    AND COALESCE(full_cr_cs.cs_sales_price, 0) > 50
    AND (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = full_cr_cs.cr_refunded_customer_sk
    ) > 0
ORDER BY brand_profit_rank, i.i_item_id
OFFSET 0
LIMIT 100
