WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        td.t_hour,
        i.i_brand,
        i.i_item_id,
        c.c_customer_id,
        ca.ca_state,
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        sm.sm_type,
        r.r_reason_desc,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        wr.wr_return_amt,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_sales_price,
        wp.wp_url
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_brand = 'Brand#23'
      AND ca.ca_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'TX'
),
unpivoted AS (
    SELECT
        b.*,
        return_amount
    FROM base b
    CROSS JOIN UNNEST(ARRAY[b.cr_return_amount, b.sr_return_amt, b.wr_return_amt]) AS t(return_amount)
),
agg AS (
    SELECT
        s_store_id,
        i_brand,
        ca_state,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_units_sold,
        SUM(return_amount) AS total_return_amount,
        AVG(ss_sales_price) AS avg_sales_price,
        MIN(ss_sales_price) AS min_sales_price,
        MAX(ss_sales_price) AS max_sales_price
    FROM unpivoted
    GROUP BY s_store_id, i_brand, ca_state
)
SELECT
    a.s_store_id,
    a.i_brand,
    a.ca_state,
    a.unique_customers,
    a.total_sales,
    a.total_units_sold,
    a.total_return_amount,
    a.avg_sales_price,
    a.min_sales_price,
    a.max_sales_price,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_sales DESC) AS sales_rank_by_store
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
