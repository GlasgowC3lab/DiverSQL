WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_returned_date_sk,
        i.i_item_id,
        i.i_brand,
        d_ret.d_year,
        w.w_city,
        w.w_gmt_offset,
        r.r_reason_desc,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        p.p_promo_name,
        cc.cc_name,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        s.s_store_name,
        web.web_name
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sales
      ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site web
      ON ws.ws_web_site_sk = web.web_site_sk
    JOIN date_dim d_web_open
      ON web.web_open_date_sk = d_web_open.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND w.w_city = 'Riverside'
      AND r.r_reason_desc LIKE '%size%'
      AND w.w_gmt_offset = -5.00
      AND i.i_brand = 'Brand#12'
),
agg AS (
    SELECT
        i_item_id AS item_id,
        d_year AS year,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_sales_price * ws_quantity) AS total_sales_amount
    FROM base
    GROUP BY i_item_id, d_year
),
high_return AS (
    SELECT
        item_id,
        year,
        total_return_amount,
        total_sales_amount,
        LAG(total_return_amount) OVER (PARTITION BY year ORDER BY total_return_amount) AS prev_return_amount,
        SUM(total_return_amount) OVER (PARTITION BY year ORDER BY total_return_amount ROWS UNBOUNDED PRECEDING) AS cumulative_return_amount
    FROM agg
    WHERE total_return_amount > 1000
),
high_sales AS (
    SELECT
        item_id,
        year,
        total_return_amount,
        total_sales_amount,
        LAG(total_return_amount) OVER (PARTITION BY year ORDER BY total_return_amount) AS prev_return_amount,
        SUM(total_return_amount) OVER (PARTITION BY year ORDER BY total_return_amount ROWS UNBOUNDED PRECEDING) AS cumulative_return_amount
    FROM agg
    WHERE total_sales_amount > 20000
)
SELECT *
FROM high_return
EXCEPT
SELECT *
FROM high_sales
ORDER BY year DESC, total_return_amount DESC
LIMIT 100
