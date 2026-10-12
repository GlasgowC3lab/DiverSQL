WITH
-- Catalog sales with related dimensions
cs AS (
    SELECT
        cs.cs_item_sk,
        i.i_category,
        i.i_item_id,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        ca.ca_state,
        p.p_discount_active,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 1000
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_income_band_sk BETWEEN 3 AND 5
      AND ca.ca_state IN ('CA', 'TX')
      AND p.p_discount_active = 'Y'
),
-- Store returns with related dimensions
sr AS (
    SELECT
        sr.sr_item_sk,
        i.i_category,
        i.i_item_id,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cd.cd_credit_rating AS sr_credit_rating,
        hd.hd_income_band_sk AS sr_income_band,
        ca.ca_state AS sr_state,
        s.s_store_name,
        sr.sr_returned_date_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN "store" s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 50
      AND cd.cd_credit_rating <> 'Low Risk'
      AND hd.hd_income_band_sk <= 4
      AND ca.ca_state = 'NY'
      AND s.s_store_name LIKE '%Store%'
),
-- Web sales with related dimensions
ws AS (
    SELECT
        ws.ws_item_sk,
        i.i_category,
        i.i_item_id,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        cd.cd_credit_rating AS ws_credit_rating,
        hd.hd_income_band_sk AS ws_income_band,
        ca.ca_state AS ws_state,
        wp.wp_link_count,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_quantity >= 2
      AND ws.ws_ext_sales_price BETWEEN 500 AND 5000
      AND cd.cd_credit_rating = 'High Risk'
      AND hd.hd_income_band_sk = 2
      AND ca.ca_state = 'FL'
      AND wp.wp_link_count > 5
),
-- Web returns with related dimensions (and link to web_sales)
wr AS (
    SELECT
        wr.wr_item_sk,
        i.i_category,
        i.i_item_id,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        cd.cd_credit_rating AS wr_credit_rating,
        hd.hd_income_band_sk AS wr_income_band,
        ca.ca_state AS wr_state,
        wp.wp_char_count,
        wr.wr_order_number
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 20
      AND cd.cd_credit_rating = 'Low Risk'
      AND hd.hd_income_band_sk >= 1
      AND ca.ca_state = 'WA'
      AND wp.wp_char_count < 2000
),
-- Small dimension for a cross‑join
discount_tiers AS (
    SELECT 0 AS tier UNION ALL SELECT 10 UNION ALL SELECT 20 UNION ALL SELECT 30
),
-- Combine the four fact sources; use FULL OUTER JOIN between cs and sr
combined AS (
    SELECT
        COALESCE(cs.cs_item_sk, sr.sr_item_sk, ws.ws_item_sk, wr.wr_item_sk) AS item_sk,
        COALESCE(cs.i_category, sr.i_category, ws.i_category, wr.i_category) AS category,
        COALESCE(cs.i_item_id, sr.i_item_id, ws.i_item_id, wr.i_item_id) AS item_id,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_returns,
        COUNT(*) AS transaction_cnt
    FROM cs
    FULL OUTER JOIN sr ON cs.cs_item_sk = sr.sr_item_sk
    LEFT JOIN ws  ON ws.ws_item_sk = COALESCE(cs.cs_item_sk, sr.sr_item_sk)
    LEFT JOIN wr  ON wr.wr_item_sk = COALESCE(cs.cs_item_sk, sr.sr_item_sk, ws.ws_item_sk)
    GROUP BY GROUPING SETS (
        (cs.cs_item_sk, cs.i_category, cs.i_item_id),
        (sr.sr_item_sk, sr.i_category, sr.i_item_id),
        (ws.ws_item_sk, ws.i_category, ws.i_item_id),
        (wr.wr_item_sk, wr.i_category, wr.i_item_id)
    )
),
-- Final enrichment, window function, CASE, LATERAL and EXISTS
final_enriched AS (
    SELECT
        c.item_sk,
        c.category,
        c.item_id,
        c.total_sales,
        c.total_returns,
        c.web_sales,
        c.web_returns,
        c.transaction_cnt,
        CASE
            WHEN c.total_sales > 10000 THEN 'HIGH'
            WHEN c.total_sales BETWEEN 5000 AND 10000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_level,
        RANK() OVER (PARTITION BY c.category ORDER BY c.total_sales DESC) AS sales_rank,
        l.avg_ws_price,
        dt.tier
    FROM combined c
    CROSS JOIN discount_tiers dt
    LEFT JOIN LATERAL (
        SELECT AVG(ws2.ws_ext_sales_price) AS avg_ws_price
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = c.item_sk
    ) l ON true
    WHERE dt.tier IN (0, 10, 20)
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_item_sk = c.item_sk AND p.p_discount_active = 'Y'
      )
)
SELECT
    item_sk,
    category,
    item_id,
    total_sales,
    total_returns,
    web_sales,
    web_returns,
    transaction_cnt,
    sales_level,
    sales_rank,
    avg_ws_price,
    tier
FROM final_enriched
WHERE sales_rank <= 5
ORDER BY category, sales_rank
LIMIT 100
