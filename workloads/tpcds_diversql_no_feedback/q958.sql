WITH base_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        d.d_year,
        i.i_brand_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand
    FROM
        web_sales ws
        INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
        INNER JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        INNER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        d.d_year,
        i.i_brand_id
)
SELECT
    s.s_store_name,
    ib2.ib_upper_bound AS income_band_upper,
    SUM(ba.total_sales) AS store_sales,
    SUM(ba.total_qty) AS store_quantity,
    AVG(ba.avg_discount) AS avg_discount_across_sales
FROM
    base_agg ba
    RIGHT OUTER JOIN store_returns sr ON sr.sr_item_sk = ba.ws_item_sk
        AND sr.sr_returned_date_sk = ba.ws_sold_date_sk
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    INNER JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
WHERE
    ba.d_year = 2001
    AND ba.i_brand_id IN (10005006, 5003002)
    AND ba.total_qty > 5
    AND EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk = ba.ws_sold_date_sk
    )
    AND EXISTS (
        SELECT 1 FROM call_center cc
        WHERE cc.cc_closed_date_sk = ba.ws_sold_date_sk
    )
GROUP BY
    s.s_store_name,
    ib2.ib_upper_bound
HAVING
    SUM(ba.total_sales) > 10000
ORDER BY
    store_sales DESC
LIMIT 100
