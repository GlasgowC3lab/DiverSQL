WITH returns_agg AS (
    SELECT
        cr_item_sk,
        cr_warehouse_sk,
        cr_order_number,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_customer_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk,
        SUM(cr_net_loss) AS total_cr_net_loss
    FROM catalog_returns
    GROUP BY
        cr_item_sk,
        cr_warehouse_sk,
        cr_order_number,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_customer_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk
)
SELECT
    w.w_warehouse_name,
    i.i_category,
    i.i_brand,
    SUM(ra.total_cr_net_loss + sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT ra.cr_order_number) AS order_cnt,
    CASE
        WHEN SUM(ra.total_cr_net_loss + sr.sr_net_loss) > (
            SELECT AVG(cr_net_loss) FROM catalog_returns
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM returns_agg ra
-- join catalog sales (order and item details)
JOIN catalog_sales cs
    ON ra.cr_item_sk = cs.cs_item_sk
   AND ra.cr_order_number = cs.cs_order_number
-- join a second warehouse for the sales record (different role)
JOIN warehouse w2
    ON cs.cs_warehouse_sk = w2.w_warehouse_sk
-- join item dimension (used also by store_returns)
JOIN item i
    ON ra.cr_item_sk = i.i_item_sk
-- join original warehouse (from return)
JOIN warehouse w
    ON ra.cr_warehouse_sk = w.w_warehouse_sk
-- join store returns for the same item
JOIN store_returns sr
    ON ra.cr_item_sk = sr.sr_item_sk
-- join customers in various roles
JOIN customer c_refunded
    ON ra.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON ra.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
-- join household demographics in various roles
JOIN household_demographics hd_refunded
    ON ra.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON ra.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
-- join customer addresses in various roles
JOIN customer_address ca_refunded
    ON ra.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON ra.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
GROUP BY
    w.w_warehouse_name,
    i.i_category,
    i.i_brand
ORDER BY total_net_loss DESC
LIMIT 100
