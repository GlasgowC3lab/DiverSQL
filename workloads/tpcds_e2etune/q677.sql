WITH returned_items AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_returning_customer_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returned_date_sk,
        cr.cr_fee,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_ship_cost,
        cr.cr_return_tax,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_country,
    sm.sm_type AS shipping_mode,
    COUNT(DISTINCT r.cr_returning_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT r.cr_refunded_customer_sk) AS distinct_refunded_customers,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_net_loss,
    AVG(r.cr_return_quantity) AS avg_return_quantity,
    SUM(i.i_current_price * r.cr_return_quantity) AS total_returned_item_value,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(hd_returning.hd_income_band_sk) AS avg_returning_income_band,
    AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band
FROM returned_items r
JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON r.cr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd_returning ON r.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_refunded ON r.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
WHERE w.w_country = 'United States'
  AND sm.sm_type IN ('AIR', 'GROUND')
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    w.w_country,
    sm.sm_type
ORDER BY total_return_amount DESC
LIMIT 10
