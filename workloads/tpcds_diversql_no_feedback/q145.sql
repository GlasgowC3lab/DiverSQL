WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        inv_l.total_on_hand
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = d.d_date_sk
    ) AS inv_l ON TRUE
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_size = 'large'
        AND cd.cd_marital_status = 'M'
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND p.p_discount_active = 'Y'
        AND cc.cc_state = 'CA'
        AND ss.ss_quantity > 5
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_amount > 0
        )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        cd.cd_gender,
        inv_l.total_on_hand
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.d_year,
    sa.cd_gender,
    sa.total_net_paid,
    sa.sales_cnt,
    sa.total_on_hand,
    avg_overall.avg_total_net_paid
FROM sales_agg sa
CROSS JOIN (
    SELECT AVG(total_net_paid) AS avg_total_net_paid
    FROM sales_agg
) avg_overall
WHERE sa.total_net_paid > avg_overall.avg_total_net_paid
ORDER BY sa.total_net_paid DESC
LIMIT 100
