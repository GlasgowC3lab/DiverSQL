WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_bill_hdemo_sk,
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_qty
    FROM catalog_sales
    WHERE cs_list_price > 50
      AND cs_ext_ship_cost < 1000
      AND cs_sold_date_sk BETWEEN 2450815 AND 2451200
    GROUP BY cs_item_sk, cs_call_center_sk, cs_catalog_page_sk, cs_promo_sk, cs_bill_hdemo_sk, cs_order_number
)
SELECT
    store_name,
    reason_desc,
    sum_sales,
    sum_profit,
    sum_catalog_return,
    sum_store_return,
    sum_web_return,
    ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY sum_sales DESC) AS sales_rank
FROM (
    SELECT
        COALESCE(s.s_store_name, 'ALL_STORES') AS store_name,
        COALESCE(r_store.r_reason_desc, 'ALL_REASONS') AS reason_desc,
        SUM(sa.total_sales) AS sum_sales,
        SUM(sa.total_profit) AS sum_profit,
        SUM(cr.cr_return_amount) AS sum_catalog_return,
        SUM(sr.sr_return_amt) AS sum_store_return,
        SUM(wr.wr_return_amt) AS sum_web_return
    FROM sales_agg sa
    JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = sa.cs_order_number
    LEFT JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND (s.s_market_id IN (1, 2, 8) OR s.s_market_id IS NULL)
    GROUP BY GROUPING SETS (
        (s.s_store_name, r_store.r_reason_desc),
        (s.s_store_name),
        (r_store.r_reason_desc),
        ()
    )
) t
ORDER BY sum_sales DESC
LIMIT 100
