WITH
    item_sample AS (
        SELECT *
        FROM item
        TABLESAMPLE BERNOULLI (10)
    ),
    avg_net_paid AS (
        SELECT avg(ss_net_paid) AS val
        FROM store_sales
    )
SELECT
    COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) AS sold_date_sk,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    ca.ca_city,
    cd.cd_gender AS customer_gender,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ws.ws_net_paid,
    -- correlated subquery: total store sales for this item
    (
        SELECT sum(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
    ) AS total_item_store_sales,
    -- compare against an uncorrelated scalar subquery (average net paid)
    CASE WHEN ss.ss_net_paid > (SELECT val FROM avg_net_paid) THEN 1 ELSE 0 END AS high_volume_flag,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) DESC) AS row_num
FROM
    store_sales ss
FULL OUTER JOIN
    store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
INNER JOIN
    item_sample i
        ON (ss.ss_item_sk = i.i_item_sk OR sr.sr_item_sk = i.i_item_sk)
LEFT JOIN
    promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN
    customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN
    income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN
    customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN
    catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN
    catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN
    ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN
    web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN
    customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN
    customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN
    web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN
    web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN
    inventory inv
        ON i.i_item_sk = inv.inv_item_sk
WHERE
    ss.ss_net_paid > (SELECT val FROM avg_net_paid)
ORDER BY
    row_num
LIMIT 100
