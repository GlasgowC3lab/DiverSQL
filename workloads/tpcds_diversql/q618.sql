WITH
catalog_sales_part AS (
    SELECT
        d_sold.d_year                                   AS year,
        i.i_category                                    AS category,
        SUM(cs.cs_net_paid_inc_ship_tax)                AS sales_amount,
        COUNT(DISTINCT cs.cs_order_number)              AS cnt,
        ca.ca_zip                                       AS zip,
        hd.hd_income_band_sk                            AS income_band_sk,
        ib.ib_lower_bound                               AS income_lower,
        CAST(NULL AS INTEGER)                           AS income_upper,
        cs.cs_item_sk                                   AS item_sk,
        wp.wp_web_page_id                               AS wp_id,
        d_first.d_date                                  AS first_sale_date
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_first
      ON c.c_first_sales_date_sk = d_first.d_date_sk
    WHERE i.i_current_price > (
        SELECT AVG(i2.i_current_price)
        FROM item i2 TABLESAMPLE BERNOULLI (10)
    )
      AND ca.ca_zip = '90419'
    GROUP BY
        d_sold.d_year,
        i.i_category,
        ca.ca_zip,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        cs.cs_item_sk,
        wp.wp_web_page_id,
        d_first.d_date
),
store_sales_part AS (
    SELECT
        d_store.d_year                                   AS year,
        i2.i_category                                    AS category,
        SUM(ss.ss_net_paid_inc_tax)                      AS sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number)              AS cnt,
        ca2.ca_zip                                      AS zip,
        hd2.hd_income_band_sk                           AS income_band_sk,
        CAST(NULL AS INTEGER)                           AS income_lower,
        ib2.ib_upper_bound                               AS income_upper,
        ss.ss_item_sk                                    AS item_sk,
        wp2.wp_web_page_id                               AS wp_id,
        d_first2.d_date                                  AS first_sale_date
    FROM store_sales ss
    JOIN date_dim d_store
      ON ss.ss_sold_date_sk = d_store.d_date_sk
    JOIN time_dim t2
      ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN item i2
      ON ss.ss_item_sk = i2.i_item_sk
    JOIN promotion p2
      ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN customer c2
      ON ss.ss_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2
      ON ss.ss_addr_sk = ca2.ca_address_sk
    JOIN household_demographics hd2
      ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2
      ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN web_page wp2
      ON wp2.wp_customer_sk = c2.c_customer_sk
    JOIN date_dim d_first2
      ON c2.c_first_sales_date_sk = d_first2.d_date_sk
    WHERE i2.i_current_price < (
        SELECT MAX(i3.i_current_price)
        FROM item i3
    )
    GROUP BY
        d_store.d_year,
        i2.i_category,
        ca2.ca_zip,
        hd2.hd_income_band_sk,
        ib2.ib_upper_bound,
        ss.ss_item_sk,
        wp2.wp_web_page_id,
        d_first2.d_date
),
returns_part AS (
    SELECT
        d_ret.d_year                                   AS year,
        i_ret.i_category                               AS category,
        SUM(cr.cr_return_amount)                       AS sales_amount,
        COUNT(*)                                        AS cnt,
        ca_ret.ca_zip                                   AS zip,
        hd_ret.hd_income_band_sk                       AS income_band_sk,
        ib_ret.ib_lower_bound                           AS income_lower,
        CAST(NULL AS INTEGER)                         AS income_upper,
        cr.cr_item_sk                                   AS item_sk,
        wp_ret.wp_web_page_id                           AS wp_id,
        d_first_ret.d_date                              AS first_sale_date
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret
      ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN customer c_ret
      ON cr.cr_refunded_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ret
      ON cr.cr_refunded_addr_sk = ca_ret.ca_address_sk
    JOIN household_demographics hd_ret
      ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret
      ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    JOIN web_page wp_ret
      ON wp_ret.wp_customer_sk = c_ret.c_customer_sk
    JOIN date_dim d_first_ret
      ON c_ret.c_first_sales_date_sk = d_first_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        i_ret.i_category,
        ca_ret.ca_zip,
        hd_ret.hd_income_band_sk,
        ib_ret.ib_lower_bound,
        cr.cr_item_sk,
        wp_ret.wp_web_page_id,
        d_first_ret.d_date
),
union_all_sales AS (
    SELECT * FROM catalog_sales_part
    UNION
    SELECT * FROM store_sales_part
    UNION
    SELECT * FROM returns_part
),
final AS (
    SELECT
        u.year,
        u.category,
        SUM(u.sales_amount)                     AS total_sales,
        SUM(u.cnt)                               AS total_cnt,
        COUNT(DISTINCT u.zip)                    AS distinct_zip_cnt,
        MAX(u.income_lower)                      AS max_income_lower,
        MAX(u.income_upper)                      AS max_income_upper,
        u.item_sk,
        u.wp_id,
        u.first_sale_date
    FROM union_all_sales u
    WHERE u.sales_amount > (
        SELECT SUM(cs.cs_net_paid_inc_ship_tax)
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk = (
            SELECT MIN(d_date_sk) FROM date_dim
        )
    )
    GROUP BY
        u.year,
        u.category,
        u.item_sk,
        u.wp_id,
        u.first_sale_date
)
SELECT
    f.year,
    f.category,
    f.total_sales,
    f.total_cnt,
    f.distinct_zip_cnt,
    f.max_income_lower,
    f.max_income_upper,
    f.item_sk,
    f.wp_id,
    f.first_sale_date,
    la.avg_item_paid
FROM final f
CROSS JOIN LATERAL (
    SELECT AVG(cs4.cs_net_paid) AS avg_item_paid
    FROM catalog_sales cs4
    WHERE cs4.cs_item_sk = f.item_sk
) AS la
ORDER BY f.total_sales DESC, f.year
LIMIT 100
