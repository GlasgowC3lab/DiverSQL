WITH returns_agg AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        cr.cr_ship_mode_sk,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_tax > 5.00
    GROUP BY cr.cr_order_number, cr.cr_item_sk, cr.cr_ship_mode_sk, cr.cr_returning_addr_sk
)
SELECT
    sm.sm_type AS ship_mode,
    ca.ca_state AS return_state,
    COUNT(DISTINCT r.cr_order_number) AS num_orders,
    SUM(r.total_return_loss) AS total_net_loss,
    SUM(cs.cs_net_paid_inc_ship) AS total_sales,
    SUM(r.total_return_loss) / NULLIF(SUM(cs.cs_net_paid_inc_ship), 0) AS loss_ratio,
    AVG(r.total_return_tax) AS avg_return_tax
FROM returns_agg r
JOIN catalog_sales cs
    ON r.cr_order_number = cs.cs_order_number
    AND r.cr_item_sk = cs.cs_item_sk
JOIN ship_mode sm
    ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
    ON r.cr_returning_addr_sk = ca.ca_address_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY sm.sm_type, ca.ca_state
HAVING SUM(cs.cs_net_paid_inc_ship) > 100000
ORDER BY loss_ratio DESC
LIMIT 50
