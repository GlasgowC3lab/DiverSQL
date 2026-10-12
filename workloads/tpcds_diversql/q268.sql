WITH joined AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        ws.ws_item_sk,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_name,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        r_wr.r_reason_desc        AS web_return_reason,
        r_sr.r_reason_desc        AS store_return_reason,
        wp.wp_type                AS web_page_type,
        wp_wr.wp_type             AS web_return_page_type
    FROM web_sales ws
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM reason r_check
        WHERE r_check.r_reason_desc = 'Promotion'
          AND r_check.r_reason_sk = r_wr.r_reason_sk
    )
),
agg AS (
    SELECT
        s_store_name,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        SUM(ws_ext_sales_price)               AS total_ext_sales,
        SUM(sr_return_quantity)               AS total_store_return_qty,
        SUM(wr_return_quantity)               AS total_web_return_qty,
        COUNT(DISTINCT ws_order_number)       AS distinct_orders
    FROM joined
    GROUP BY
        s_store_name,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
)
SELECT
    s_store_name,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_ext_sales,
    total_store_return_qty,
    total_web_return_qty,
    distinct_orders,
    ROW_NUMBER() OVER (ORDER BY total_ext_sales DESC)           AS row_num,
    LAG(total_ext_sales) OVER (ORDER BY total_ext_sales DESC)   AS lag_total_sales
FROM agg
ORDER BY total_ext_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
