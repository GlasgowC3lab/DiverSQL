WITH sales_union AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk,
        cs.cs_ext_sales_price AS sales_amount,
        hd.hd_buy_potential AS buy_potential,
        p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 0

    UNION

    SELECT
        ss.ss_ticket_number AS order_number,
        ss.ss_item_sk AS item_sk,
        ss.ss_ext_sales_price AS sales_amount,
        hd.hd_buy_potential AS buy_potential,
        p.p_promo_name AS promo_name
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > 0
)
SELECT
    su.order_number,
    su.item_sk,
    su.sales_amount,
    su.buy_potential,
    su.promo_name
FROM sales_union su
WHERE su.order_number NOT IN (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
ORDER BY su.sales_amount DESC
LIMIT 100
