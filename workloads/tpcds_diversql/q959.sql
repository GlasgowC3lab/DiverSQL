WITH base_fact AS (
    SELECT
        COALESCE(cr.cr_returned_date_sk, wr.wr_returned_date_sk) AS return_date_sk,
        COALESCE(cr.cr_item_sk, wr.wr_item_sk) AS item_sk,
        COALESCE(cr.cr_refunded_customer_sk, wr.wr_refunded_customer_sk) AS customer_sk,
        COALESCE(cr.cr_refunded_hdemo_sk, wr.wr_refunded_hdemo_sk) AS hdemo_sk,
        COALESCE(cr.cr_refunded_addr_sk, wr.wr_refunded_addr_sk) AS addr_sk,
        COALESCE(cr.cr_return_quantity, wr.wr_return_quantity) AS return_quantity,
        COALESCE(cr.cr_return_amount, wr.wr_return_amt) AS return_amount,
        COALESCE(cr.cr_return_tax, wr.wr_return_tax) AS return_tax,
        COALESCE(cr.cr_return_ship_cost, wr.wr_return_ship_cost) AS return_ship_cost,
        COALESCE(cr.cr_net_loss, wr.wr_net_loss) AS net_loss,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        COALESCE(cr.cr_reason_sk, wr.wr_reason_sk) AS reason_sk,
        wr.wr_web_page_sk,
        CASE WHEN cr.cr_return_amount IS NOT NULL THEN 'Catalog' ELSE 'Web' END AS source_flag
    FROM catalog_returns cr
    FULL OUTER JOIN web_returns wr
        ON cr.cr_item_sk = wr.wr_item_sk
       AND cr.cr_refunded_customer_sk = wr.wr_refunded_customer_sk
       AND cr.cr_refunded_hdemo_sk = wr.wr_refunded_hdemo_sk
       AND cr.cr_refunded_addr_sk = wr.wr_refunded_addr_sk
),
union_fact AS (
    SELECT * FROM base_fact WHERE return_amount > 100
    UNION
    SELECT * FROM base_fact WHERE net_loss > 200
)
SELECT
    i.i_brand,
    cc.cc_state,
    r.r_reason_desc,
    hd.hd_buy_potential,
    uf.source_flag,
    COUNT(*) AS return_cnt,
    SUM(uf.return_amount) AS total_return_amount,
    AVG(uf.return_amount) AS avg_return_amount,
    MIN(uf.return_amount) AS min_return_amount,
    MAX(uf.return_amount) AS max_return_amount
FROM union_fact uf
JOIN item i ON i.i_item_sk = uf.item_sk
JOIN customer c ON c.c_customer_sk = uf.customer_sk
JOIN household_demographics hd ON hd.hd_demo_sk = uf.hdemo_sk
JOIN customer_address ca ON ca.ca_address_sk = uf.addr_sk
LEFT JOIN call_center cc ON cc.cc_call_center_sk = uf.cr_call_center_sk
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = uf.cr_catalog_page_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = uf.cr_ship_mode_sk
JOIN reason r ON r.r_reason_sk = uf.reason_sk
LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = uf.wr_web_page_sk
WHERE i.i_current_price BETWEEN 50 AND 200
  AND cc.cc_state = 'CA'
  AND ca.ca_country = 'United States'
  AND ib.ib_upper_bound <= 80000
GROUP BY i.i_brand, cc.cc_state, r.r_reason_desc, hd.hd_buy_potential, uf.source_flag
HAVING SUM(uf.return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
