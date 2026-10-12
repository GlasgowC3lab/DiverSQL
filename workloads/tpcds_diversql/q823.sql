WITH
    catalog_cte AS (
        SELECT
            cr.cr_item_sk,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cr.cr_reason_sk,
            cr.cr_call_center_sk,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            i.i_wholesale_cost,
            i.i_size,
            i.i_color,
            r.r_reason_desc,
            cc.cc_name,
            p.p_promo_name,
            c.c_customer_sk,
            cd.cd_demo_sk,
            ca.ca_address_sk,
            c.c_birth_year
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON i.i_item_sk = p.p_item_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE i.i_size = 'medium'
          AND i.i_wholesale_cost BETWEEN 1.0 AND 5.0
          AND cc.cc_mkt_desc LIKE '%new%'
          AND cr.cr_return_amount > 500
          AND cr.cr_return_quantity >= 2
          AND c.c_birth_year = 1975
    ),
    store_cte AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_return_amt,
            sr.sr_net_loss,
            sr.sr_reason_sk,
            sr.sr_store_sk,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            i.i_wholesale_cost,
            i.i_color,
            r.r_reason_desc,
            s.s_store_name,
            p.p_promo_name,
            c.c_customer_sk,
            cd.cd_demo_sk,
            ca.ca_address_sk,
            c.c_birth_year
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN promotion p ON i.i_item_sk = p.p_item_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE s.s_state = 'CA'
          AND i.i_color = 'red'
          AND sr.sr_return_amt > 500
          AND sr.sr_return_quantity >= 1
          AND EXISTS (
                SELECT 1 FROM promotion p2
                WHERE p2.p_item_sk = i.i_item_sk
                  AND p2.p_discount_active = 'Y'
          )
          AND c.c_birth_month = 7
    ),
    web_cte AS (
        SELECT
            wr.wr_item_sk,
            wr.wr_return_amt,
            wr.wr_net_loss,
            wr.wr_reason_sk,
            wr.wr_web_page_sk,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            i.i_wholesale_cost,
            i.i_size,
            r.r_reason_desc,
            wp.wp_url,
            p.p_promo_name,
            c.c_customer_sk,
            cd.cd_demo_sk,
            ca.ca_address_sk,
            c.c_birth_year
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN promotion p ON i.i_item_sk = p.p_item_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE wp.wp_type = 'product'
          AND i.i_category = 'Electronics'
          AND wr.wr_return_amt > 300
          AND wr.wr_return_quantity >= 1
          AND wp.wp_url LIKE 'http%://%'
          AND c.c_birth_day = 15
    ),
    intersect_items AS (
        SELECT cr_item_sk AS item_sk FROM catalog_cte
        INTERSECT
        SELECT sr_item_sk AS item_sk FROM store_cte
    ),
    full_outer AS (
        SELECT
            COALESCE(sc.sr_item_sk, wc.wr_item_sk) AS item_sk,
            sc.sr_return_amt,
            wc.wr_return_amt,
            sc.sr_net_loss,
            wc.wr_net_loss,
            sc.sr_store_sk,
            wc.wr_web_page_sk
        FROM store_cte sc
        FULL OUTER JOIN web_cte wc
          ON sc.sr_item_sk = wc.wr_item_sk
    )
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    cc.cc_name AS call_center_name,
    s.s_store_name,
    wp.wp_url,
    COUNT(*) AS total_returns,
    SUM(COALESCE(c.cr_return_amount,0) + COALESCE(sr.sr_return_amt,0) + COALESCE(wr.wr_return_amt,0)) AS total_return_amount,
    AVG(COALESCE(sr.sr_net_loss,0) + COALESCE(wr.wr_net_loss,0)) AS avg_net_loss,
    MIN(i.i_wholesale_cost) AS min_wholesale_cost,
    MAX(i.i_wholesale_cost) AS max_wholesale_cost
FROM catalog_cte c
LEFT JOIN store_cte sr ON c.cr_item_sk = sr.sr_item_sk
LEFT JOIN web_cte wr ON c.cr_item_sk = wr.wr_item_sk
LEFT JOIN item i ON c.cr_item_sk = i.i_item_sk
LEFT JOIN reason r ON c.cr_reason_sk = r.r_reason_sk
LEFT JOIN call_center cc ON c.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.cr_item_sk IN (SELECT item_sk FROM intersect_items)
GROUP BY
    i.i_item_id,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    cc.cc_name,
    s.s_store_name,
    wp.wp_url
ORDER BY total_return_amount DESC
LIMIT 100
