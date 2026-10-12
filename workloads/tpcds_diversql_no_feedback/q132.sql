WITH ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    )
    GROUP BY
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk
),
sr_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    )
    GROUP BY
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk
)
SELECT
    d.d_year,
    i.i_item_id,
    i.i_brand,
    cd.cd_credit_rating,
    hd.hd_income_band_sk,
    ws_agg.total_sales,
    ws_agg.avg_discount,
    ws_agg.order_cnt,
    sr_agg.total_returns,
    sr_agg.return_cnt,
    ws_agg.sales_rank,
    wsite.web_name
FROM ws_agg
JOIN store_returns sr
    ON ws_agg.ws_item_sk = sr.sr_item_sk
    AND ws_agg.ws_sold_date_sk = sr.sr_returned_date_sk
    AND ws_agg.ws_bill_customer_sk = sr.sr_customer_sk
JOIN sr_agg
    ON sr.sr_item_sk = sr_agg.sr_item_sk
    AND sr.sr_returned_date_sk = sr_agg.sr_returned_date_sk
    AND sr.sr_return_time_sk = sr_agg.sr_return_time_sk
    AND sr.sr_customer_sk = sr_agg.sr_customer_sk
JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN date_dim d
    ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ws_agg.ws_sold_time_sk = t.t_time_sk
JOIN customer c
    ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite
    ON ws_agg.ws_web_site_sk = wsite.web_site_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    i.i_current_price > 100
    AND cd.cd_credit_rating = 'Good'
    AND hd.hd_income_band_sk = 5
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ws_agg.ws_promo_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY d.d_year DESC, ws_agg.total_sales DESC
LIMIT 100
