WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_store_credit,
        cr.cr_fee,
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_type,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        hd.hd_income_band_sk,
        s.s_store_id,
        wp.wp_web_page_id,
        ws.web_site_id,
        wr.wr_return_amt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
      AND i.i_current_price > 20
      AND sm.sm_type = 'AIR'
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_income_band_sk = 5
),
agg_2001 AS (
    SELECT
        d_year,
        cp_department,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        COUNT(DISTINCT i_item_id) AS distinct_items,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(wr_return_amt) AS total_web_return_amount,
        AVG(cr_return_quantity) AS avg_return_qty,
        MIN(cr_net_loss) AS min_net_loss,
        MAX(cr_net_loss) AS max_net_loss,
        CASE WHEN SUM(cr_return_amount) > 100000 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category
    FROM base
    GROUP BY d_year, cp_department
    HAVING SUM(cr_return_amount) > 5000
),
agg_2000 AS (
    SELECT
        d_year,
        cp_department,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        COUNT(DISTINCT i_item_id) AS distinct_items,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(wr_return_amt) AS total_web_return_amount,
        AVG(cr_return_quantity) AS avg_return_qty,
        MIN(cr_net_loss) AS min_net_loss,
        MAX(cr_net_loss) AS max_net_loss,
        CASE WHEN SUM(cr_return_amount) > 100000 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category
    FROM base
    WHERE d_year = 2000
    GROUP BY d_year, cp_department
)
SELECT *
FROM agg_2001
EXCEPT
SELECT *
FROM agg_2000
ORDER BY total_return_amount DESC
LIMIT 100
