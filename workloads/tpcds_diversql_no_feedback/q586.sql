WITH base AS (
    SELECT
        p.p_promo_name AS p_promo_name,
        cp.cp_department AS cp_department,
        d.d_year AS d_year,
        SUM(cs.cs_net_profit) AS sum_profit,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(ss.ss_net_paid) AS sum_store_sales,
        SUM(ws.ws_net_paid) AS sum_web_sales,
        SUM(wr.wr_net_loss) AS sum_web_return_loss
    FROM catalog_sales cs
    RIGHT OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
    GROUP BY ROLLUP (p.p_promo_name, cp.cp_department, d.d_year)
)
SELECT
    p_promo_name,
    cp_department,
    d_year,
    sum_profit,
    sum_return_amount,
    sum_store_sales,
    sum_web_sales,
    sum_web_return_loss,
    (sum_profit - sum_return_amount) AS net_profit_after_returns
FROM base
ORDER BY sum_profit DESC
LIMIT 100
