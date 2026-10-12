WITH store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        d.d_date,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_rank,
        hd.hd_income_band_sk,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
      AND ib.ib_upper_bound > 50000
      AND i.i_category = 'Sports'
    GROUP BY i.i_item_sk, i.i_item_id, d.d_date, d.d_year, hd.hd_income_band_sk, ib.ib_upper_bound
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        d.d_date,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS web_rank,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        cp.cp_description
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = ws.ws_item_sk
                               AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND p.p_channel_email = 'N'
      AND cp.cp_department = 'Home'
    GROUP BY i.i_item_sk, i.i_item_id, d.d_date, d.d_year, hd.hd_income_band_sk, ib.ib_upper_bound, cp.cp_description
),
intersect_items AS (
    SELECT i_item_id FROM store_agg WHERE store_rank <= 10
    INTERSECT
    SELECT i_item_id FROM web_agg WHERE web_sales > 2000
)
SELECT
    si.i_item_id,
    sa.store_sales,
    wa.web_sales,
    sa.store_rank,
    wa.web_rank,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wa.cp_description
FROM intersect_items si
JOIN store_agg sa ON si.i_item_id = sa.i_item_id
JOIN web_agg wa ON si.i_item_id = wa.i_item_id
JOIN income_band ib ON sa.hd_income_band_sk = ib.ib_income_band_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_item_sk = sa.i_item_sk
      AND r.r_reason_desc LIKE '%duplicate purchase%'
)
LIMIT 100
