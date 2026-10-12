WITH
    ss_agg AS (
        SELECT
            ss_item_sk,
            ss_sold_date_sk,
            ss_promo_sk,
            SUM(ss_net_paid) AS total_net_paid,
            COUNT(*) AS cnt_sales
        FROM store_sales
        WHERE ss_quantity > 1
          AND ss_sold_date_sk BETWEEN 2450545 AND 2450750
        GROUP BY ss_item_sk, ss_sold_date_sk, ss_promo_sk
    ),
    cr_detail AS (
        SELECT
            cr_item_sk,
            cr_returned_date_sk,
            cr_refunded_customer_sk,
            cr_refunded_cdemo_sk,
            cr_refunded_addr_sk,
            cr_ship_mode_sk,
            SUM(cr_return_amount) AS total_return_amount,
            COUNT(*) AS cnt_returns,
            SUM(cr_fee) AS total_fee
        FROM catalog_returns
        WHERE cr_return_quantity > 0
          AND cr_returned_date_sk BETWEEN 2450545 AND 2450750
          AND cr_fee < 5
        GROUP BY cr_item_sk, cr_returned_date_sk,
                 cr_refunded_customer_sk,
                 cr_refunded_cdemo_sk,
                 cr_refunded_addr_sk,
                 cr_ship_mode_sk
    ),
    intersect_items AS (
        SELECT cr_item_sk AS item_sk FROM cr_detail
        INTERSECT
        SELECT ss_item_sk FROM ss_agg
    ),
    inventory_agg AS (
        SELECT
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        WHERE inv_warehouse_sk IN (9, 10)
        GROUP BY inv_date_sk
    ),
    cross_dim AS (
        SELECT d_year, seq
        FROM (
            SELECT d_year FROM date_dim WHERE d_year IN (1998, 1999, 2000) LIMIT 3
        ) d
        CROSS JOIN (
            SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3
        ) s
    )
SELECT
    d.d_year,
    cd.cd_gender,
    sm.sm_type,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    i.total_qty_on_hand,
    ss.total_net_paid,
    ss.cnt_sales,
    cr.total_return_amount,
    cr.cnt_returns,
    CASE WHEN cd.cd_education_status = 'Advanced Degree' THEN 1 ELSE 0 END AS advanced_edu_flag,
    cd_dim.seq AS seq_num
FROM intersect_items it
JOIN ss_agg ss
    ON ss.ss_item_sk = it.item_sk
JOIN cr_detail cr
    ON cr.cr_item_sk = it.item_sk
JOIN date_dim d
    ON d.d_date_sk = ss.ss_sold_date_sk
JOIN promotion p
    ON p.p_promo_sk = ss.ss_promo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN customer c
    ON c.c_customer_sk = cr.cr_refunded_customer_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cr.cr_refunded_addr_sk
JOIN inventory_agg i
    ON i.inv_date_sk = d.d_date_sk
CROSS JOIN cross_dim cd_dim
WHERE d.d_year = 1998
  AND p.p_channel_email = 'N'
ORDER BY d.d_year DESC, ss.total_net_paid DESC
LIMIT 100
