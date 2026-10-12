WITH base_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_year AS year_sold,
        i.i_category,
        i.i_brand,
        c.c_first_name,
        c.c_last_name,
        ib.ib_upper_bound,
        sm.sm_type,
        w.w_warehouse_name,
        p.p_promo_sk,
        p.p_discount_active,
        cc.cc_name AS call_center_name,
        wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d_sold.d_year = 2001
      AND ib.ib_upper_bound > 100000
      AND sm.sm_type = 'AIR'
),
returns_data AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        d_ret.d_year AS year_return,
        s.s_store_name,
        s.s_tax_percentage
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d_ret.d_year = 2001
      AND s.s_tax_percentage > 0.05
),
web_site_data AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d_ws.d_year AS year_open
    FROM web_site ws
    JOIN date_dim d_ws ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
)
SELECT
    bd.cs_order_number,
    bd.i_category,
    bd.i_brand,
    bd.c_first_name,
    bd.c_last_name,
    bd.cs_net_profit,
    rd.sr_return_amt,
    rd.s_store_name,
    bd.call_center_name,
    bd.wp_url,
    ws.web_name,
    RANK() OVER (PARTITION BY bd.year_sold ORDER BY bd.cs_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY bd.i_category ORDER BY bd.cs_net_paid DESC) AS sales_rownum,
    (SELECT SUM(cs2.cs_net_paid) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = bd.cs_item_sk) AS total_item_sales
FROM base_data bd
FULL OUTER JOIN web_site_data ws ON bd.year_sold = ws.year_open
JOIN returns_data rd ON bd.cs_item_sk = rd.sr_item_sk AND bd.cs_bill_customer_sk = rd.sr_customer_sk
WHERE NOT EXISTS (
    SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = bd.p_promo_sk AND p2.p_discount_active = 'N'
)
ORDER BY profit_rank
LIMIT 100
