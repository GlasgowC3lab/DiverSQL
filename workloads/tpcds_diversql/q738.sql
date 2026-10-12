WITH sampled_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_quantity,
        ss_wholesale_cost,
        ss_list_price,
        ss_sales_price,
        ss_ext_discount_amt,
        ss_ext_sales_price,
        ss_ext_wholesale_cost,
        ss_ext_list_price,
        ss_ext_tax,
        ss_coupon_amt,
        ss_net_paid,
        ss_net_paid_inc_tax,
        ss_net_profit
    FROM store_sales TABLESAMPLE BERNOULLI (5)
    WHERE ss_coupon_amt > 100
      AND ss_ext_discount_amt BETWEEN 20 AND 5000
      AND ss_net_paid_inc_tax > 1000
),
addressed_sales AS (
    SELECT
        ss.*, 
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_address_id
    FROM sampled_sales ss
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_zip LIKE '8%'
),
intersect_orders AS (
    SELECT cr_order_number FROM catalog_returns WHERE cr_reversed_charge > 1000
    INTERSECT
    SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 500
),
except_orders AS (
    SELECT cr_order_number FROM catalog_returns WHERE cr_reversed_charge > 100
    EXCEPT
    SELECT cr_order_number FROM catalog_returns WHERE cr_return_quantity = 0
),
final AS (
    SELECT
        asales.ss_ticket_number               AS ticket_number,
        asales.ss_item_sk                     AS item_sk,
        asales.ca_state                       AS state,
        asales.ca_zip                         AS zip,
        asales.ss_net_paid_inc_tax            AS net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY asales.ca_state ORDER BY asales.ss_net_paid_inc_tax DESC) AS rn_state,
        cr_join.cr_return_amount              AS sample_return_amount,
        lr.total_return_amount                AS total_return_amount
    FROM addressed_sales asales
    JOIN catalog_returns cr_join
      ON cr_join.cr_refunded_addr_sk = asales.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_addr_sk = asales.ca_address_sk
          AND cr2.cr_order_number IN (SELECT cr_order_number FROM intersect_orders)
    ) lr
    WHERE asales.ss_ticket_number IN (SELECT cr_order_number FROM except_orders)
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr3
          WHERE cr3.cr_refunded_addr_sk = asales.ca_address_sk
            AND cr3.cr_reversed_charge > 200
      )
)
SELECT
    ticket_number,
    item_sk,
    state,
    zip,
    net_paid_inc_tax,
    rn_state,
    total_return_amount
FROM final
ORDER BY net_paid_inc_tax DESC, rn_state
LIMIT 100
