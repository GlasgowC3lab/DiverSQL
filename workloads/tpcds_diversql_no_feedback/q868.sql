WITH joined AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_mkt_id,
        cc.cc_county,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r.r_reason_desc,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        i.i_current_price,
        t_ret.t_hour AS return_hour,
        t_sold.t_hour AS sale_hour,
        ib.ib_lower_bound,
        hd.hd_buy_potential,
        cd.cd_gender,
        wp.wp_type
    FROM call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cc.cc_mkt_id = 3
      AND cc.cc_county = 'Jackson County'
      AND i.i_current_price > 1000
      AND t_ret.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'home page'
),
sub_sales AS (
    SELECT cc_call_center_id,
           SUM(ss_ext_sales_price) AS total_sales
    FROM joined
    GROUP BY cc_call_center_id
    HAVING SUM(ss_ext_sales_price) > 50000
),
sub_returns AS (
    SELECT cc_call_center_id,
           SUM(cr_return_amount) AS total_returns
    FROM joined
    GROUP BY cc_call_center_id
    HAVING SUM(cr_return_amount) > 10000
)
SELECT cc_call_center_id
FROM sub_sales
INTERSECT
SELECT cc_call_center_id
FROM sub_returns
ORDER BY cc_call_center_id
LIMIT 100
