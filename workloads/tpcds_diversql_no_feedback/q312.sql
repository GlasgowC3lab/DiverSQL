WITH filtered_returns AS (
    SELECT sr.*, hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_vehicle_count
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt BETWEEN 20 AND 500
      AND hd.hd_vehicle_count >= 1
), filtered_sales AS (
    SELECT ws.*, hd.hd_demo_sk, hd.hd_income_band_sk, ws_site.web_name
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_ext_sales_price > 0
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    ws_site.web_name,
    SUM(fr.sr_return_amt) AS total_return_amount,
    SUM(fs.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT fr.sr_ticket_number) AS return_transactions,
    COUNT(DISTINCT fs.ws_order_number) AS sales_transactions,
    AVG(CASE WHEN fr.sr_return_amt > 100 THEN fr.sr_return_amt END) AS avg_large_return,
    MIN(fr.sr_return_amt) AS min_return_amount,
    MAX(fs.ws_ext_sales_price) AS max_sale_amount
FROM filtered_returns fr
JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd ON fr.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN filtered_sales fs ON fs.hd_demo_sk = hd.hd_demo_sk
JOIN web_site ws_site ON fs.ws_web_site_sk = ws_site.web_site_sk
WHERE r.r_reason_id = 'AAAAAAAACBAAAAAA'
GROUP BY CUBE (
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    ws_site.web_name
)
ORDER BY total_return_amount DESC
LIMIT 100
