WITH joined AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        c.c_birth_year,
        sm.sm_type,
        s.s_gmt_offset,
        cs.cs_ext_sales_price AS cs_sales,
        cs.cs_ext_discount_amt AS cs_discount,
        ws.ws_ext_sales_price AS ws_sales,
        ws.ws_ext_discount_amt AS ws_discount,
        sr.sr_return_amt AS sr_return
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE s.s_gmt_offset = -8.00
      AND sm.sm_type = 'OVERNIGHT'
      AND c.c_birth_year >= 1980
)
SELECT
    i_item_id,
    i_item_desc,
    SUM(cs_sales + ws_sales) AS total_sales,
    SUM(cs_discount + ws_discount) AS total_discount,
    SUM(COALESCE(sr_return, 0)) AS total_returns,
    (SUM(cs_sales + ws_sales) - SUM(COALESCE(sr_return, 0))) AS net_sales
FROM joined
GROUP BY i_item_id, i_item_desc
HAVING (SUM(cs_sales + ws_sales) - SUM(COALESCE(sr_return, 0))) > 10000
ORDER BY net_sales DESC
LIMIT 100
